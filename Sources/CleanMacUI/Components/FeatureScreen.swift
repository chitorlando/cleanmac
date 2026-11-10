import SwiftUI

/// Full screen of a feature: the dark canvas lit by the feature's glows.
///
/// Content gets a plain primary foreground style, so borderless buttons and icons stay bright on
/// the canvas. Secondary and tertiary levels are left to the system on purpose: native controls
/// such as menu pickers and bordered buttons draw their bezels with those levels, and brighter
/// ones would turn the bezels light gray behind white labels. Components that place supporting
/// text near the glows, like ``ActionBar``, brighten it themselves.
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
                .foregroundStyle(Color.primary)
        }
        .environment(\.colorScheme, .dark)
    }
}
