import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var auth: AuthViewModel
    let summary: AccountSummary

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                CardView(title: "Profile") {
                    DetailRow(label: "Name", value: summary.name)
                    DetailRow(label: "Email", value: summary.email)
                }
                CardView(title: "Lines") {
                    ForEach(summary.lines) { line in
                        DetailRow(label: line.name, value: line.plan)
                    }
                }
                PrimaryButton(title: "Sign out", style: .outlined) {
                    Task { await auth.signOut() }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("My account")
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(Theme.muted)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
