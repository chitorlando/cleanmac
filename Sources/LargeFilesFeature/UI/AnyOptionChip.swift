import CleanMacUI
import SwiftUI

/// Small capsule beside the title of a filter group with the option that shows every file.
///
/// It stays highlighted while nothing else in the group is chosen, and choosing it clears the group.
struct AnyOptionChip: View {
    let title: Text
    let isSelected: Bool
    let theme: FeatureTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            title
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(SelectionHighlight(isSelected: isSelected, theme: theme))
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
