import SwiftUI

struct HomeView: View {
    @StateObject private var model: HomeViewModel

    init(api: APIClient, onSessionExpired: @escaping @MainActor () -> Void) {
        _model = StateObject(wrappedValue: HomeViewModel(api: api, onSessionExpired: onSessionExpired))
    }

    var body: some View {
        content
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationDestination(for: AccountSummary.self) { AccountView(summary: $0) }
            .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            CardView {
                Text(message).foregroundStyle(Theme.danger)
                PrimaryButton(title: "Try again", style: .outlined) {
                    Task { await model.load() }
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxHeight: .infinity, alignment: .top)
        case .loaded(let summary):
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Hi, \(summary.firstName)").font(.title2.bold())
                    CardView(title: "Balance due") {
                        Text(summary.balanceDue, format: .currency(code: "USD")).font(.largeTitle.bold())
                        Text("Due \(summary.formattedDueDate)").font(.footnote).foregroundStyle(Theme.muted)
                    }
                    ForEach(summary.lines) { line in
                        CardView(title: line.name) {
                            Text("\(line.plan) · \(line.phoneNumber)")
                            UsageBar(used: line.dataUsedGb, limit: line.dataLimitGb, unit: "GB")
                        }
                    }
                    NavigationLink(value: summary) {
                        Text("View account")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(Theme.primary)
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.primary))
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .refreshable { await model.load() }
        }
    }
}
