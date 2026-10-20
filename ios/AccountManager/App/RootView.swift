import SwiftUI

/// Signed-out users only ever see the login screen; signed-in users only see the app stack.
struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            switch auth.status {
            case .loading:
                ProgressView()
            case .signedOut:
                LoginView()
            case .signedIn:
                NavigationStack {
                    HomeView(api: auth.api, onSessionExpired: { auth.sessionExpired() })
                }
            }
        }
        .task { auth.restoreSession() }
    }
}
