import CleanMacUI
import SwiftUI

/// Right pane: details of the focused app, or a hint when none is focused.
struct AppDetailPane: View {
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            if let app = viewModel.focusedApp {
                AppDetailView(app: app, viewModel: viewModel, theme: theme)
            } else {
                Text("Select an app to see its files.", bundle: .module, comment: "Shown in the detail pane when no app is focused.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
