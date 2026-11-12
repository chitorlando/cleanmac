import CleanMacUI
import SwiftUI

/// The login items grouped by scope, where the user picks the agents to remove.
struct LoginItemsBrowsingView: View {
    @ObservedObject var viewModel: LoginItemsViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 20) {
            LoginItemsHeader(
                itemCount: viewModel.items.count,
                orphanedCount: viewModel.orphanedCount
            ) { viewModel.openLoginItemsSettings() }
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.sections) { section in
                        LoginItemSectionCard(section: section, viewModel: viewModel, theme: theme)
                    }
                }
            }
            .scrollIndicators(.never)
            ActionBar(
                secondaryTitle: Text("List Again", bundle: .module, comment: "Button that reads the login items again."),
                primaryTitle: removeTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme,
                onSecondary: { viewModel.startLoading() },
                onPrimary: { viewModel.remove() }
            )
        }
        .frame(maxWidth: 820)
    }

    private var removeTitle: Text {
        viewModel.selectedCount == 0
            ? Text("Move to Trash", bundle: .module, comment: "Disabled button shown before any login item is selected.")
            : Text(
                "Move \(viewModel.selectedCount) Items to Trash",
                bundle: .module,
                comment: "Button that moves the selected login items to the Trash. The argument is how many."
            )
    }
}
