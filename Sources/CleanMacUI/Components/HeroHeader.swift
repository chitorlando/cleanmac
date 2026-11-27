import SwiftUI

/// Large icon, title and subtitle that introduce a feature.
///
/// Title and subtitle wrap instead of truncating, as in every `HeroLayout`. The icon answers
/// the pointer, bouncing or leaning a little.
public struct HeroHeader: View {
    private let symbolName: String
    private let title: String
    private let subtitle: String
    private let theme: FeatureTheme

    public init(symbolName: String, title: String, subtitle: String, theme: FeatureTheme) {
        self.symbolName = symbolName
        self.title = title
        self.subtitle = subtitle
        self.theme = theme
    }

    public var body: some View {
        HeroLayout(subtitle: subtitle) {
            Image(systemName: symbolName)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(theme.gradient)
                .glow(theme.primary.opacity(0.6), radius: 24)
                .reactsToHover()
                .accessibilityHidden(true)
        } title: {
            Text(title)
        }
    }
}
