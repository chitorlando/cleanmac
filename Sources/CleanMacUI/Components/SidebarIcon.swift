import SwiftUI

/// Small colored tile with a symbol, in the style of System Settings.
///
/// On macOS 14 and later, the symbol bounces each time its entry gets selected. Earlier
/// systems, and Reduce Motion, keep it still: the highlight of the selection already shows it.
public struct SidebarIcon: View {
    /// Side of the tile, the same as the icons in the sidebar of System Settings.
    private static let size: CGFloat = 20

    private let symbolName: String
    private let theme: FeatureTheme
    private let isSelected: Bool

    /// - Parameter isSelected: Whether the entry the icon stands for is selected.
    public init(symbolName: String, theme: FeatureTheme, isSelected: Bool = false) {
        self.symbolName = symbolName
        self.theme = theme
        self.isSelected = isSelected
    }

    public var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .modifier(SelectionBounce(isSelected: isSelected))
            .frame(width: Self.size, height: Self.size)
            .background(theme.gradient, in: .rect(cornerRadius: Self.size / 4))
            .accessibilityHidden(true)
    }
}

/// Bounces a symbol each time what it stands for gets selected, on macOS 14 and later.
private struct SelectionBounce: ViewModifier {
    let isSelected: Bool
    @Environment(\.motionPolicy) private var motion
    /// How many times the entry got selected, which the symbol bounces at.
    @State private var selections = 0

    func body(content: Content) -> some View {
        if motion.allowsTravel {
            if #available(macOS 14, *) {
                content
                    .symbolEffect(.bounce, value: selections)
                    .onChange(of: isSelected) { _, isNowSelected in
                        if isNowSelected {
                            selections += 1
                        }
                    }
            } else {
                content
            }
        } else {
            content
        }
    }
}
