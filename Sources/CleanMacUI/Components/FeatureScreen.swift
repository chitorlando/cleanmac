import SwiftUI

/// Full screen of a feature: the dark canvas lit by the feature's glows,
/// with secondary and tertiary text bright enough to stay readable on it.
public struct FeatureScreen<Content: View>: View {
    private let theme: FeatureTheme
    private let content: Content

    public init(theme: FeatureTheme, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    public var body: some View {
        ZStack {
            FeatureBackground(theme: theme)
            content
                .foregroundStyle(Color.primary, Palette.secondaryText, Palette.tertiaryText)
        }
        .environment(\.colorScheme, .dark)
    }
}
