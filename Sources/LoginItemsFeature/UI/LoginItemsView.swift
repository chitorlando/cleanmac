import CleanMacCore
import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase and, above it,
/// the app the list is limited to when another feature asked for its items only.
struct LoginItemsView: View {
    @ObservedObject var viewModel: LoginItemsViewModel
    let theme: FeatureTheme

    var body: some View {
        FeatureScreen(theme: theme) {
            VStack(spacing: 16) {
                if let app = appOnScreen {
                    LoginItemsAppPill(app: app, theme: theme) { viewModel.showAllItems() }
                        .transition(.opacity)
                }
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .phaseTransition()
            }
            .padding(32)
        }
        .animation(.smooth(duration: 0.35), value: viewModel.phase)
        .animation(.smooth(duration: 0.35), value: viewModel.appFilter)
    }

    /// The app the list is limited to, on the screens that read or list the items. A removal
    /// and its report show no app: the limit applies to the list shown after them.
    private var appOnScreen: LoginItemOwner? {
        switch viewModel.phase {
        case .loading, .browsing: viewModel.appFilter
        case .intro, .removing, .finished: nil
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .intro:
            LoginItemsIntroView(theme: theme) { viewModel.startLoading() }
        case .loading:
            BusyView(
                message: Text("Reading login items…", bundle: .module, comment: "Status shown while the login items are read."),
                theme: theme
            )
        case .browsing where viewModel.sections.isEmpty:
            if let app = viewModel.appFilter {
                LoginItemsNoneForAppView(
                    app: app,
                    theme: theme,
                    onShowAll: { viewModel.showAllItems() },
                    onOpenSettings: { viewModel.openLoginItemsSettings() }
                )
            } else {
                LoginItemsNoneFoundView(theme: theme) { viewModel.openLoginItemsSettings() }
            }
        case .browsing:
            LoginItemsBrowsingView(viewModel: viewModel, theme: theme)
        case .removing:
            BusyView(theme: theme)
        case .finished(let report):
            LoginItemsFinishedView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
