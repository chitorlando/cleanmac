@testable import CleanMacUI
import SwiftUI
import Testing

/// Glow buttons draw dark labels on a feature's gradient, so the whole gradient must
/// stay light enough to read them.
struct FeatureThemeContrastTests {
    /// The project's minimum, above WCAG's 7:1 for enhanced contrast.
    private static let minimumContrast = 8.0
    private static let samples = 40

    @Test func measuresContrastWithTheWCAGFormula() {
        let black = SRGBColor(red: 0, green: 0, blue: 0)
        let white = SRGBColor(red: 1, green: 1, blue: 1)

        #expect(abs(black.contrastRatio(with: white) - 21) < 0.001)
        #expect(white.contrastRatio(with: white) == 1)
        #expect(abs(SRGBColor(red: 0.5, green: 0.5, blue: 0.5).contrastRatio(with: black) - 5.28) < 0.01)
    }

    @Test func checksEveryFeatureTheme() {
        #expect(FeatureTheme.featureThemes.count >= 9)
    }

    /// Samples the gradient mixing the encoded sRGB components, which is never lighter in
    /// between than mixing linear light, so it covers either way of drawing it.
    @Test(arguments: FeatureTheme.featureThemes.keys.sorted())
    func darkLabelsStayReadableAcrossTheGradient(themeName: String) throws {
        let theme = try #require(FeatureTheme.featureThemes[themeName])
        let label = try SRGBColor(Palette.canvas)
        let start = try SRGBColor(theme.primary)
        let end = try SRGBColor(theme.secondary)

        let worst = (0...Self.samples)
            .map { start.mixed(with: end, by: Double($0) / Double(Self.samples)).contrastRatio(with: label) }
            .min() ?? 0

        #expect(worst >= Self.minimumContrast, "\(themeName) reaches only \(worst):1")
    }
}
