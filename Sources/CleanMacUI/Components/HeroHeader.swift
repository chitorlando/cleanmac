import SwiftUI

/// Large icon, title and subtitle that introduce a feature.
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
        VStack(spacing: 18) {
            Image(systemName: symbolName)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(theme.gradient)
                .shadow(color: theme.primary.opacity(0.6), radius: 24)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
    }
}
