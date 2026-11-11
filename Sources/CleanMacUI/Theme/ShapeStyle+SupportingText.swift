import SwiftUI

public extension ShapeStyle where Self == Color {
    /// The least important text on a feature screen, such as paths, versions and bundle IDs.
    ///
    /// It sits below secondary text but, unlike the system's tertiary color, keeps 4.5:1 on the
    /// canvas, its cards and the edges of the glows.
    static var supportingText: Color { Color.white.opacity(0.62) }
}
