import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    enum State {
        case loading
        case loaded(AccountSummary)
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    private let api: APIClient
    private let onSessionExpired: @MainActor () -> Void

    init(api: APIClient, onSessionExpired: @escaping @MainActor () -> Void) {
        self.api = api
        self.onSessionExpired = onSessionExpired
    }

    func load() async {
        do {
            let summary: AccountSummary = try await api.get("api/account/summary")
            state = .loaded(summary)
        } catch APIError.sessionExpired {
            onSessionExpired()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
