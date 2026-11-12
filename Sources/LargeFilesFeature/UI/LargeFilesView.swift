import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct LargeFilesView: View {
    @ObservedObject var viewModel: LargeFilesViewModel
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
            LargeFilesIntroView(theme: theme) { viewModel.startScan() }
        case .scanning:
            LargeFilesScanningView(viewModel: viewModel, theme: theme)
        case .review where viewModel.files.isEmpty:
            LargeFilesNoneFoundView(
                wasStoppedEarly: viewModel.wasStoppedEarly,
                minimumSize: viewModel.minimumSize,
                scopeFolder: viewModel.scope.folder,
                theme: theme,
                onScanAgain: { viewModel.startScan() },
                onScanHome: { viewModel.scanHome() }
            )
        case .review:
            LargeFilesReviewView(viewModel: viewModel, theme: theme)
        case .removing:
            BusyView(theme: theme)
        case .finished(let report):
            CleanupCompletionView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
