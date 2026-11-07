import SwiftUI

/// Small colored tile with a symbol, in the style of System Settings.
public struct SidebarIcon: View {
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
            .frame(width: 24, height: 24)
            .background(theme.gradient, in: .rect(cornerRadius: 6))
            .accessibilityHidden(true)
    }
}
