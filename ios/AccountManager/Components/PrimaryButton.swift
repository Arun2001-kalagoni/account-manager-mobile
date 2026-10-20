import SwiftUI

struct PrimaryButton: View {
    enum Style { case filled, outlined }

    let title: String
    var style: Style = .filled
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    private var foreground: Color { style == .filled ? .white : Theme.primary }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    Text(title).font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(foreground)
            .background(style == .filled ? Theme.primary : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.primary, lineWidth: style == .outlined ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1)
        .accessibilityLabel(title)
    }
}
