import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var canSubmit: Bool { email.contains("@") && password.count >= 8 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Welcome back").font(.title.bold())
                Text("Sign in to manage your account, plans, and devices.")
                    .foregroundStyle(Theme.muted)
                CardView {
                    LabeledField(label: "Email", text: $email, keyboard: .emailAddress, contentType: .username)
                    LabeledField(label: "Password", text: $password, isSecure: true, contentType: .password, error: errorMessage)
                    PrimaryButton(title: "Sign in", isLoading: isLoading, isDisabled: !canSubmit) {
                        Task { await submit() }
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .padding(.top, Theme.Spacing.lg)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    @MainActor
    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
