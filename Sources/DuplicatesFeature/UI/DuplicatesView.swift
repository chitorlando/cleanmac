import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct DuplicatesView: View {
    let viewModel: DuplicatesViewModel
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
            DuplicatesIntroView(theme: theme) { viewModel.startScan() }
        case .scanning:
            DuplicatesScanningView(viewModel: viewModel, theme: theme)
        case .review where viewModel.groups.isEmpty:
            DuplicatesNoneFoundView(wasStoppedEarly: viewModel.wasStoppedEarly, theme: theme) {
                viewModel.startScan()
            }
        case .review:
            DuplicatesReviewView(viewModel: viewModel, theme: theme)
        case .removing:
            BusyView(theme: theme)
        case .finished(let report):
            CleanupCompletionView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
