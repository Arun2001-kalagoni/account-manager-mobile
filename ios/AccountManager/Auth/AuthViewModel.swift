import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    enum Status { case loading, signedOut, signedIn }

    @Published private(set) var status: Status = .loading
    let api: APIClient
    private let tokenStore: TokenStore

    init(api: APIClient, tokenStore: TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func restoreSession() {
        guard status == .loading else { return }
        let saved = try? tokenStore.load()
        status = saved == nil ? .signedOut : .signedIn
    }

    func signIn(email: String, password: String) async throws {
        try await api.login(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        status = .signedIn
    }

    func signOut() async {
        await api.logout()
        status = .signedOut
    }

    func sessionExpired() {
        status = .signedOut
    }
}
