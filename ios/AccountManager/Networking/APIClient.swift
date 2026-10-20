import Foundation

struct TokenPair: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
}

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

/// Talks to the Spring Boot API. An actor, so token refresh state is never touched from two threads at once.
actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: TokenStore
    private let decoder = JSONDecoder()
    private var refreshTask: Task<TokenPair, Error>?

    init(baseURL: URL, session: URLSession = .shared, tokenStore: TokenStore) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws {
        let request = try jsonRequest("api/auth/login", body: ["username": email, "password": password])
        let (data, response) = try await send(request)
        switch response.statusCode {
        case 200:
            try store(try decoder.decode(TokenResponse.self, from: data))
        case 401:
            throw APIError.invalidCredentials
        default:
            throw APIError.server(status: response.statusCode)
        }
    }

    func logout() async {
        if let tokens = try? tokenStore.load(),
           let request = try? jsonRequest("api/auth/logout", body: ["refreshToken": tokens.refreshToken]) {
            _ = try? await send(request)
        }
        try? tokenStore.clear()
    }

    // MARK: - Authenticated requests

    /// GET that refreshes an expired access token once and retries, so the user is not signed out mid-session.
    func get<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        guard let tokens = try tokenStore.load() else { throw APIError.sessionExpired }

        var (data, response) = try await send(authorizedGet(path, accessToken: tokens.accessToken))
        if response.statusCode == 401 {
            let accessToken = try await validAccessToken(replacing: tokens.accessToken)
            (data, response) = try await send(authorizedGet(path, accessToken: accessToken))
        }
        guard (200..<300).contains(response.statusCode) else {
            throw response.statusCode == 401 ? APIError.sessionExpired : APIError.server(status: response.statusCode)
        }
        return try decoder.decode(T.self, from: data)
    }

    /// Returns a usable access token after `rejected` got a 401.
    /// Concurrent callers share one in-flight refresh, and a caller that lost a race reuses the newer stored token.
    private func validAccessToken(replacing rejected: String) async throws -> String {
        if let inFlight = refreshTask {
            return try await inFlight.value.accessToken
        }
        if let current = try tokenStore.load(), current.accessToken != rejected {
            return current.accessToken
        }
        let task = Task { try await performRefresh() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value.accessToken
    }

    private func performRefresh() async throws -> TokenPair {
        guard let current = try tokenStore.load() else { throw APIError.sessionExpired }
        let request = try jsonRequest("api/auth/refresh", body: ["refreshToken": current.refreshToken])
        let (data, response) = try await send(request)
        guard response.statusCode == 200 else {
            try? tokenStore.clear()
            throw APIError.sessionExpired
        }
        return try store(try decoder.decode(TokenResponse.self, from: data))
    }

    // MARK: - Helpers

    @discardableResult
    private func store(_ response: TokenResponse) throws -> TokenPair {
        let pair = TokenPair(accessToken: response.accessToken, refreshToken: response.refreshToken)
        try tokenStore.save(pair)
        return pair
    }

    private func authorizedGet(_ path: String, accessToken: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func jsonRequest(_ path: String, body: [String: String]) throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw APIError.transport }
            return (data, http)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport
        }
    }
}
