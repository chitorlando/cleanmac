import CleanMacUI
import SwiftUI

/// App list and details side by side, with the uninstall action below, which asks first.
struct UninstallerBrowsingView: View {
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                AppListPane(viewModel: viewModel, theme: theme)
                    .frame(width: 340)
                AppDetailPane(viewModel: viewModel, theme: theme)
            }
            ActionBar(
                secondaryTitle: Text("Scan Again", bundle: .module, comment: "Button that reloads the list of installed apps."),
                primaryTitle: uninstallTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme,
                onSecondary: { viewModel.startLoading() },
                onPrimary: { viewModel.requestUninstall() }
            )
        }
        .trashConfirmation(
            confirmation.title,
            isPresented: viewModel.pendingUninstall != nil,
            message: confirmation.message,
            onConfirm: { viewModel.uninstall() },
            onDismiss: { viewModel.cancelUninstall() }
        )
    }

    /// What the dialog asks about. It only shows while there is something to ask.
    private var confirmation: UninstallConfirmation {
        viewModel.pendingUninstall ?? UninstallConfirmation(appNames: [], leftoverCount: 0, size: 0)
    }

    private var uninstallTitle: Text {
        guard viewModel.hasSelection else {
            return Text("Uninstall", bundle: .module, comment: "Disabled uninstall button shown while nothing is selected.")
        }
        return Text(
            "Uninstall \(viewModel.selectedSize.formattedByteCount)",
            bundle: .module,
            comment: "Button that moves the selected apps and files to the Trash. The argument is a size, such as “1.2 GB”."
        )
    }
}
