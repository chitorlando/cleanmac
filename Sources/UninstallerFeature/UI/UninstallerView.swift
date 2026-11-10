import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct UninstallerView: View {
    @ObservedObject var viewModel: UninstallerViewModel
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
            UninstallerIntroView(theme: theme) { viewModel.startLoading() }
        case .loading:
            UninstallerLoadingView(viewModel: viewModel, theme: theme)
        case .browsing:
            UninstallerBrowsingView(viewModel: viewModel, theme: theme)
        case .uninstalling:
            BusyView(theme: theme)
        case .finished(let report):
            CleanupCompletionView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
