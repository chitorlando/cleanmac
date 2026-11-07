import SwiftUI

/// Dark canvas lit by two soft glows in the feature's colors.
public struct FeatureBackground: View {
    private let theme: FeatureTheme

    public init(theme: FeatureTheme) {
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            Palette.canvas
            glow(theme.primary, at: .topTrailing, radius: 620)
            glow(theme.secondary, at: .bottomLeading, radius: 680)
        }
        .ignoresSafeArea()
    }

    private func glow(_ color: Color, at center: UnitPoint, radius: CGFloat) -> some View {
        RadialGradient(
            colors: [color.opacity(0.45), .clear],
            center: center,
            startRadius: 20,
            endRadius: radius
        )
    }
}
