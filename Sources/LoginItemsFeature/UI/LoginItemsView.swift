import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct LoginItemsView: View {
    @ObservedObject var viewModel: LoginItemsViewModel
    let theme: FeatureTheme

    var body: some View {
        FeatureScreen(theme: theme) {
            content
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .phaseTransition()
        }
        .animation(.smooth(duration: 0.35), value: viewModel.phase)
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
            LoginItemsNoneFoundView(theme: theme) { viewModel.openLoginItemsSettings() }
        case .browsing:
            LoginItemsBrowsingView(viewModel: viewModel, theme: theme)
        case .removing:
            BusyView(theme: theme)
        case .finished(let report):
            LoginItemsFinishedView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
