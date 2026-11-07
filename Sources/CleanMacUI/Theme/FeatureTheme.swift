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
        secondary: Color(red: 0.50, green: 0.30, blue: 0.92)
    )

    static let neutral = FeatureTheme(
        primary: Color(white: 0.62),
        secondary: Color(white: 0.38)
    )
}
