import CleanMacUI
import SwiftUI

/// The login items grouped by scope, where the user picks the agents to remove and confirms
/// it before they're removed.
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
                    ForEach(Array(viewModel.sections.enumerated()), id: \.element.id) { order, section in
                        LoginItemSectionCard(section: section, viewModel: viewModel, theme: theme)
                            .staggeredEntrance(order: order)
                    }
                }
                .revealsRowsInTurn()
            }
            .scrollIndicators(.never)
            ActionBar(
                secondaryTitle: Text("List Again", bundle: .module, comment: "Button that reads the login items again."),
                primaryTitle: removeTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme,
                onSecondary: { viewModel.startLoading() },
                onPrimary: { viewModel.requestRemoval() }
            )
        }
        .frame(maxWidth: 820)
        .trashConfirmation(
            confirmationTitle,
            isPresented: viewModel.isConfirmingRemoval,
            message: Text(
                "They stop running at your next login. You can put them back from the Trash.",
                bundle: .module,
                comment: "Message of the dialog that asks before moving login items to the Trash, which keep running until the next login."
            ),
            onConfirm: { viewModel.remove() },
            onDismiss: { viewModel.cancelRemoval() }
        )
    }

    private var confirmationTitle: Text {
        Text(
            "Move \(viewModel.selectedCount) login items to the Trash?",
            bundle: .module,
            comment: "Title of the dialog that asks before moving login items to the Trash. The argument is how many."
        )
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
