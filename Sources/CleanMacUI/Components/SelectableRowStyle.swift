import SwiftUI

/// Button style for list rows that can be chosen, such as the apps of a master list.
///
/// The selected row is highlighted with the feature's colors.
public struct SelectableRowStyle: ButtonStyle {
    private let isSelected: Bool
    private let theme: FeatureTheme

    public init(isSelected: Bool, theme: FeatureTheme) {
        self.isSelected = isSelected
        self.theme = theme
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SelectionHighlight(isSelected: isSelected, isPressed: configuration.isPressed, theme: theme))
            .contentShape(.rect(cornerRadius: 10))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
