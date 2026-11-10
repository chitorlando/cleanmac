import SwiftUI

/// Base colors shared by every feature screen.
enum Palette {
    static let canvas = Color(red: 0.07, green: 0.06, blue: 0.13)
    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.09)

    /// Supporting text that sits near the glows, such as quiet actions in the bottom bar.
    /// Keeps at least 4.5:1 contrast there, where the system's secondary label color falls below.
    static let secondaryText = Color.white.opacity(0.75)
}
