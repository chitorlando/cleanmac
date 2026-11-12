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
    /// Mint to teal, greener than the monitor's aqua and cerulean.
    static let systemJunk = FeatureTheme(
        primary: Color(red: 0.30, green: 0.87, blue: 0.62),
        secondary: Color(red: 0.00, green: 0.77, blue: 0.65)
    )

    /// Sky blue to periwinkle, bluer than the lavender of duplicates.
    static let uninstaller = FeatureTheme(
        primary: Color(red: 0.44, green: 0.69, blue: 1.00),
        secondary: Color(red: 0.67, green: 0.64, blue: 1.00)
    )

    /// Orange to magenta, warmer at the start than login items and more purple at the end than privacy.
    static let largeFiles = FeatureTheme(
        primary: Color(red: 1.00, green: 0.57, blue: 0.23),
        secondary: Color(red: 1.00, green: 0.50, blue: 0.87)
    )

    /// Amber to orange.
    static let maintenance = FeatureTheme(
        primary: Color(red: 1.00, green: 0.75, blue: 0.25),
        secondary: Color(red: 1.00, green: 0.57, blue: 0.16)
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

    /// Coral to a pinker red, a hue no other feature uses: redder than the orange of large
    /// files and the rose of privacy. Red only reaches 8:1 against dark labels this light.
    static let loginItems = FeatureTheme(
        primary: Color(red: 1.00, green: 0.55, blue: 0.51),
        secondary: Color(red: 1.00, green: 0.54, blue: 0.62)
    )

    /// Aqua to cerulean, a hue no other feature uses: bluer than the junk's mint and teal,
    /// greener than the uninstaller's blue. Dark button labels keep at least 8.6:1 across it.
    static let monitor = FeatureTheme(
        primary: Color(red: 0.45, green: 0.94, blue: 0.98),
        secondary: Color(red: 0.18, green: 0.74, blue: 0.95)
    )

    /// Blush to rose, a hue no other feature uses: lighter and pinker than the lavender
    /// and magenta of the duplicates. Dark button labels keep at least 8.5:1 across it.
    static let privacy = FeatureTheme(
        primary: Color(red: 1.00, green: 0.72, blue: 0.85),
        secondary: Color(red: 0.98, green: 0.55, blue: 0.76)
    )

    static let neutral = FeatureTheme(
        primary: Color(white: 0.62),
        secondary: Color(white: 0.38)
    )
}
