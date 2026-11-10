import CleanMacUI
import SwiftUI

/// Search box, "Select duplicates" checkbox and sort menu above the list of groups.
struct DuplicateGroupListControls: View {
    @Bindable var viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 12) {
            SearchField(
                text: $viewModel.query.searchText,
                prompt: Text("Search duplicates", bundle: .module, comment: "Placeholder of the field that filters the groups of duplicates by path."),
                theme: theme
            )
            HStack(spacing: 8) {
                TriStateCheckbox(
                    state: CheckState(viewModel.duplicatesSelectionState),
                    tint: theme.primary,
                    label: selectDuplicatesLabel
                ) {
                    viewModel.toggleDuplicates()
                }
                .disabled(!viewModel.canToggleDuplicates)
                selectDuplicatesLabel
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityHidden(true)
                Spacer()
                DuplicateSortPicker(sortOrder: $viewModel.query.sortOrder)
            }
            .padding(.horizontal, 10)
            .help(selectDuplicatesHelp)
        }
    }

    private var selectDuplicatesLabel: Text {
        Text("Select Duplicates", bundle: .module, comment: "Label of the checkbox that marks every copy but one in each listed group.")
    }

    private var selectDuplicatesHelp: Text {
        Text(
            "Marks every copy but one in each group. The copy suggested to keep and its clones stay unmarked.",
            bundle: .module,
            comment: "Tooltip of the checkbox that marks the duplicates of every listed group."
        )
    }
}
