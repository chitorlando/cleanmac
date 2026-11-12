import AppKit
import SwiftUI

/// A color's sRGB components, with the WCAG 2 contrast formulas.
struct SRGBColor {
    struct Unconvertible: Error {}

    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(_ color: Color) throws {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { throw Unconvertible() }
        self.init(red: srgb.redComponent, green: srgb.greenComponent, blue: srgb.blueComponent)
    }

    /// WCAG relative luminance, from 0 for black to 1 for white.
    var relativeLuminance: Double {
        0.2126 * Self.linear(red) + 0.7152 * Self.linear(green) + 0.0722 * Self.linear(blue)
    }

    /// WCAG contrast ratio, from 1 for the same color to 21 for black on white.
    func contrastRatio(with other: SRGBColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The color `fraction` of the way to `other`, mixing the encoded components.
    func mixed(with other: SRGBColor, by fraction: Double) -> SRGBColor {
        SRGBColor(
            red: red + (other.red - red) * fraction,
            green: green + (other.green - green) * fraction,
            blue: blue + (other.blue - blue) * fraction
        )
    }

    private static func linear(_ component: Double) -> Double {
        component <= 0.040_45 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
    }
}
