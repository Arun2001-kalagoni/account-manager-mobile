import SwiftUI

struct UsageBar: View {
    let used: Double
    let limit: Double
    let unit: String

    private var fraction: Double { limit > 0 ? min(used / limit, 1) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ProgressView(value: fraction)
            Text("\(used.formatted()) of \(limit.formatted()) \(unit) used")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
        }
        .accessibilityElement(children: .combine)
    }
}
