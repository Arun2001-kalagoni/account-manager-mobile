import SwiftUI

@main
struct AccountManagerApp: App {
    @StateObject private var auth: AuthViewModel

    init() {
        let store = KeychainTokenStore()
        let configured = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
        let baseURL = URL(string: configured ?? "") ?? URL(string: "http://localhost:8080")!
        let api = APIClient(baseURL: baseURL, tokenStore: store)
        _auth = StateObject(wrappedValue: AuthViewModel(api: api, tokenStore: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .tint(Theme.primary)
        }
    }
}
