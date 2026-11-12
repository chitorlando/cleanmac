import SwiftUI

/// Color identity of a feature: used for its background, icon and main actions.
public struct FeatureTheme: Sendable {
    public let primary: Color
    public let secondary: Color

    public init(primary: Color, secondary: Color) {
        self.primary = primary
        self.secondary = secondary
    }

    public var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public extension FeatureTheme {
    static let systemJunk = FeatureTheme(
        primary: Color(red: 0.30, green: 0.87, blue: 0.62),
        secondary: Color(red: 0.05, green: 0.52, blue: 0.70)
    )

    static let uninstaller = FeatureTheme(
        primary: Color(red: 0.36, green: 0.62, blue: 1.00),
        secondary: Color(red: 0.55, green: 0.40, blue: 0.98)
    )

    static let largeFiles = FeatureTheme(
        primary: Color(red: 1.00, green: 0.56, blue: 0.30),
        secondary: Color(red: 0.88, green: 0.24, blue: 0.56)
    )

    static let maintenance = FeatureTheme(
        primary: Color(red: 1.00, green: 0.75, blue: 0.25),
        secondary: Color(red: 0.94, green: 0.50, blue: 0.12)
    )

    static let duplicates = FeatureTheme(
        primary: Color(red: 0.80, green: 0.48, blue: 1.00),
        secondary: Color(red: 0.84, green: 0.24, blue: 0.72)
    )

    /// Chartreuse to leaf green, a hue no other feature uses.
    static let diskMap = FeatureTheme(
        primary: Color(red: 0.82, green: 0.92, blue: 0.32),
        secondary: Color(red: 0.42, green: 0.80, blue: 0.30)
    )

    /// Coral to crimson, a hue no other feature uses.
    static let loginItems = FeatureTheme(
        primary: Color(red: 1.00, green: 0.45, blue: 0.42),
        secondary: Color(red: 0.88, green: 0.18, blue: 0.27)
    )

    /// Aqua to cerulean, a hue no other feature uses: bluer than the junk's mint and teal,
    /// greener than the uninstaller's blue. Dark button labels keep at least 8.6:1 across it.
    static let monitor = FeatureTheme(
        primary: Color(red: 0.45, green: 0.94, blue: 0.98),
        secondary: Color(red: 0.18, green: 0.74, blue: 0.95)
    )

    static let neutral = FeatureTheme(
        primary: Color(white: 0.62),
        secondary: Color(white: 0.38)
    )
}
