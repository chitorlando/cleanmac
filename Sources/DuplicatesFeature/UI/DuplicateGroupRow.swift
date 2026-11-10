import CleanMacCore
import CleanMacUI
import SwiftUI

/// One group of duplicates in the list, with the space it can free, or a badge when its copies are all clones.
/// Clicking it shows its copies; the checkbox marks its duplicates.
///
/// It takes plain values instead of the view model, and two rows are equal when they show
/// the same, so wrapped in `.equatable()` a row is only evaluated again when it changes,
/// not on every change of the screen.
struct DuplicateGroupRow: View, Equatable {
    let group: DuplicateGroup
    let isFocused: Bool
    let selectionState: ItemSelection.State
    let theme: FeatureTheme
    let onToggle: () -> Void
    let onFocus: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TriStateCheckbox(
                state: CheckState(selectionState),
                tint: theme.primary,
                label: Text(verbatim: group.name),
                action: onToggle
            )

            DuplicateFileIcon(group: group, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: group.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(group.files.count) copies", bundle: .module, comment: "Number of identical copies in a group of duplicates.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if group.isMadeOfClones {
                CloneGroupBadge()
            } else {
                Text(group.recoverableSize.formattedByteCount)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .help(Text("Space that can be freed", bundle: .module, comment: "Tooltip of the space a group of duplicates can free."))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SelectionHighlight(isSelected: isFocused, theme: theme))
        .contentShape(.rect(cornerRadius: 10))
        .onTapGesture(perform: onFocus)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isFocused ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { onFocus() }
    }

    /// Compares what the row shows. The actions are left out: they act on the same group.
    nonisolated static func == (lhs: DuplicateGroupRow, rhs: DuplicateGroupRow) -> Bool {
        lhs.group == rhs.group
            && lhs.isFocused == rhs.isFocused
            && lhs.selectionState == rhs.selectionState
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
    }
}
