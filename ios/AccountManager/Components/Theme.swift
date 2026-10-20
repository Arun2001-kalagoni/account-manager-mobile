import SwiftUI

/// Shared design tokens so every screen and component stays consistent.
enum Theme {
    static let primary = Color(red: 0.89, green: 0.0, blue: 0.45)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let muted = Color.secondary
    static let danger = Color.red
    static let cornerRadius: CGFloat = 12

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }
}
