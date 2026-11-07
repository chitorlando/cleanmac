import CleanMacUI
import SwiftUI

/// "Select all" checkbox, search box and sort menu above the list of files.
struct LargeFileListToolbar: View {
    @Bindable var viewModel: LargeFilesViewModel
    let theme: FeatureTheme

    var body: some View {
        HStack(spacing: 12) {
            TriStateCheckbox(
                state: CheckState(viewModel.allSelectionState),
                tint: theme.primary,
                label: Text("Select All", bundle: .module, comment: "Accessibility label of the checkbox that selects every visible file.")
            ) { viewModel.toggleAll() }
            .help(Text("Select All", bundle: .module, comment: "Accessibility label of the checkbox that selects every visible file."))

            SearchField(
                text: $viewModel.filter.searchText,
                prompt: Text("Search files", bundle: .module, comment: "Placeholder of the search box over the list of large files."),
                theme: theme
            )

            LargeFileSortPicker(sortOrder: $viewModel.sortOrder)
        }
    }
}
