import CleanMacUI
import SwiftUI

/// Denser version of `SelectableRowStyle` for filter options, so every group of the
/// filter column fits at the smallest window size.
struct FilterOptionStyle: ButtonStyle {
    let isSelected: Bool
    let theme: FeatureTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SelectionHighlight(isSelected: isSelected, isPressed: configuration.isPressed, theme: theme))
            .contentShape(.rect(cornerRadius: 10))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
