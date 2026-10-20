import XCTest
@testable import AccountManager

final class APIClientTests: XCTestCase {
    private let baseURL = URL(string: "http://localhost:8080")!
    private let summaryJSON = """
    {"name":"Demo User","email":"demo@example.com","balanceDue":85.00,"dueDate":"2026-11-01",
     "lines":[{"name":"My Phone","phoneNumber":"(555) 010-2030","plan":"Unlimited Plus","dataUsedGb":18.4,"dataLimitGb":50}]}
    """
    private let freshTokensJSON = #"{"accessToken":"fresh","refreshToken":"r2","expiresIn":900}"#

    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testLoginStoresTokens() async throws {
        let store = InMemoryTokenStore()
        StubURLProtocol.handler = { _ in (200, #"{"accessToken":"a1","refreshToken":"r1","expiresIn":900}"#) }
        let api = APIClient(baseURL: baseURL, session: StubURLProtocol.session(), tokenStore: store)

        try await api.login(email: "demo@example.com", password: "Password123!")

        XCTAssertEqual(try store.load(), TokenPair(accessToken: "a1", refreshToken: "r1"))
    }

    func testLoginWithWrongPasswordThrowsInvalidCredentials() async {
        StubURLProtocol.handler = { _ in (401, "") }
        let api = APIClient(baseURL: baseURL, session: StubURLProtocol.session(), tokenStore: InMemoryTokenStore())

        do {
            try await api.login(email: "demo@example.com", password: "wrong-password")
            XCTFail("Expected invalidCredentials")
        } catch {
            XCTAssertEqual(error as? APIError, .invalidCredentials)
        }
    }

    func testExpiredAccessTokenIsRefreshedOnceAndRequestRetried() async throws {
        let store = InMemoryTokenStore(TokenPair(accessToken: "expired", refreshToken: "r1"))
        let refreshes = Counter()
        StubURLProtocol.handler = { request in
            switch request.url?.path {
            case "/api/auth/refresh":
                refreshes.increment()
                return (200, self.freshTokensJSON)
            case "/api/account/summary":
                let ok = request.value(forHTTPHeaderField: "Authorization") == "Bearer fresh"
                return ok ? (200, self.summaryJSON) : (401, "")
            default:
                return (404, "")
            }
        }
        let api = APIClient(baseURL: baseURL, session: StubURLProtocol.session(), tokenStore: store)

        let summary: AccountSummary = try await api.get("api/account/summary")

        XCTAssertEqual(summary.firstName, "Demo")
        XCTAssertEqual(refreshes.value, 1)
        XCTAssertEqual(try store.load(), TokenPair(accessToken: "fresh", refreshToken: "r2"))
    }

    func testConcurrentRequestsShareOneRefresh() async throws {
        let store = InMemoryTokenStore(TokenPair(accessToken: "expired", refreshToken: "r1"))
        let refreshes = Counter()
        StubURLProtocol.handler = { request in
            if request.url?.path == "/api/auth/refresh" {
                refreshes.increment()
                return (200, self.freshTokensJSON)
            }
            let ok = request.value(forHTTPHeaderField: "Authorization") == "Bearer fresh"
            return ok ? (200, self.summaryJSON) : (401, "")
        }
        let api = APIClient(baseURL: baseURL, session: StubURLProtocol.session(), tokenStore: store)

        async let first: AccountSummary = api.get("api/account/summary")
        async let second: AccountSummary = api.get("api/account/summary")
        _ = try await (first, second)

        XCTAssertEqual(refreshes.value, 1)
    }

    func testFailedRefreshClearsSessionAndThrowsSessionExpired() async {
        let store = InMemoryTokenStore(TokenPair(accessToken: "expired", refreshToken: "revoked"))
        StubURLProtocol.handler = { _ in (401, "") }
        let api = APIClient(baseURL: baseURL, session: StubURLProtocol.session(), tokenStore: store)

        do {
            let _: AccountSummary = try await api.get("api/account/summary")
            XCTFail("Expected sessionExpired")
        } catch {
            XCTAssertEqual(error as? APIError, .sessionExpired)
        }
        XCTAssertNil(try store.load())
    }
}
