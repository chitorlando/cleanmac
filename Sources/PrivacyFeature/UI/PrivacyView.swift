import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct PrivacyView: View {
    @ObservedObject var viewModel: PrivacyViewModel
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
            PrivacyIntroView(theme: theme) { viewModel.startScan() }
        case .scanning:
            BusyView(
                message: Text("Looking for browser caches…", bundle: .module, comment: "Status shown while browser caches are measured."),
                theme: theme
            )
        case .review where viewModel.results.isEmpty:
            PrivacyNothingFoundView(theme: theme) { viewModel.done() }
        case .review:
            PrivacyReviewView(viewModel: viewModel, theme: theme)
        case .cleaning:
            BusyView(theme: theme)
        case .finished(let report):
            PrivacyFinishedView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
