import SwiftUI

/// Small colored tile with a symbol, in the style of System Settings.
public struct SidebarIcon: View {
    /// Side of the tile, the same as the icons in the sidebar of System Settings.
    private static let size: CGFloat = 20

    private let symbolName: String
    private let theme: FeatureTheme

    public init(symbolName: String, theme: FeatureTheme) {
        self.symbolName = symbolName
        self.theme = theme
    }

    public var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: Self.size, height: Self.size)
            .background(theme.gradient, in: .rect(cornerRadius: Self.size / 4))
            .accessibilityHidden(true)
    }
}
