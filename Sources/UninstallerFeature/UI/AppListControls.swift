import CleanMacUI
import SwiftUI

/// Search box, "select all" checkbox and sort menu above the app list.
struct AppListControls: View {
    @Bindable var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 12) {
            SearchField(
                text: $viewModel.query.searchText,
                prompt: Text("Search apps", bundle: .module, comment: "Placeholder of the field that filters installed apps."),
                theme: theme
            )
            HStack(spacing: 8) {
                TriStateCheckbox(state: CheckState(viewModel.allSelectionState), tint: theme.primary) {
                    viewModel.toggleAll()
                }
                Text("Select All", bundle: .module, comment: "Label of the checkbox that selects every listed app.")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                sortMenu
            }
            .padding(.horizontal, 10)
        }
    }

    private var sortMenu: some View {
        Picker(selection: $viewModel.query.sortOrder) {
            ForEach(AppSortOrder.allCases, id: \.self) { order in
                Text(order.title).tag(order)
            }
        } label: {
            sortLabel
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .help(sortLabel)
        .fixedSize()
    }

    private var sortLabel: Text {
        Text("Sort by", bundle: .module, comment: "Label of the menu that changes the order of the app list.")
    }
}
