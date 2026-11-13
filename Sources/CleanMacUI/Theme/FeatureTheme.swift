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

    /// Lavender to orchid.
    static let duplicates = FeatureTheme(
        primary: Color(red: 0.80, green: 0.59, blue: 1.00),
        secondary: Color(red: 0.96, green: 0.50, blue: 1.00)
    )

    /// Chartreuse to leaf green, a hue no other feature uses.
    static let diskMap = FeatureTheme(
        primary: Color(red: 0.82, green: 0.92, blue: 0.32),
        secondary: Color(red: 0.42, green: 0.80, blue: 0.30)
    )

    /// Lemon to sunflower, the only yellow theme: more yellow than the amber of maintenance
    /// and warmer than the chartreuse of the disk map. Dark labels keep at least 13.6:1 across it.
    static let loginItems = FeatureTheme(
        primary: Color(red: 1.00, green: 0.96, blue: 0.52),
        secondary: Color(red: 1.00, green: 0.85, blue: 0.30)
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

    /// The background of planned features and of the empty detail pane. No button uses it.
    static let neutral = FeatureTheme(
        primary: Color(white: 0.62),
        secondary: Color(white: 0.38)
    )
}

extension FeatureTheme {
    /// Every theme a feature's buttons use, by name. Glow buttons draw dark labels on them,
    /// so a test checks their contrast: add each new feature theme here.
    static let featureThemes: [String: FeatureTheme] = [
        "systemJunk": .systemJunk,
        "uninstaller": .uninstaller,
        "largeFiles": .largeFiles,
        "maintenance": .maintenance,
        "duplicates": .duplicates,
        "diskMap": .diskMap,
        "loginItems": .loginItems,
        "monitor": .monitor,
        "privacy": .privacy
    ]
}
