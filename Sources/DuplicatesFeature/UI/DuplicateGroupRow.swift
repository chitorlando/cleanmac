import CleanMacUI
import SwiftUI

/// One group of duplicates in the list, with the space it can free, or a badge when its copies are all clones.
/// Clicking it shows its copies; the checkbox marks its duplicates.
struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    @ObservedObject var viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    private var isFocused: Bool { viewModel.focusedGroupID == group.id }

    var body: some View {
        HStack(spacing: 10) {
            TriStateCheckbox(
                state: CheckState(viewModel.selectionState(of: group)),
                tint: theme.primary,
                label: Text(verbatim: group.name)
            ) {
                viewModel.toggle(group)
            }

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
        .onTapGesture { viewModel.focusedGroupID = group.id }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isFocused ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { viewModel.focusedGroupID = group.id }
    }
}
