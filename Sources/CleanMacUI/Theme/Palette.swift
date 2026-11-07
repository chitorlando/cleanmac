import SwiftUI

/// Base colors shared by every feature screen.
enum Palette {
    static let canvas = Color(red: 0.07, green: 0.06, blue: 0.13)
    static let cardFill = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.09)

    /// Supporting text. Keeps at least 4.5:1 contrast on the canvas, its cards and the
    /// edges of its glows, where the system's secondary label color falls below.
    static let secondaryText = Color.white.opacity(0.75)

    /// Least important text, such as file paths. Same contrast goal as `secondaryText`.
    static let tertiaryText = Color.white.opacity(0.62)
}
