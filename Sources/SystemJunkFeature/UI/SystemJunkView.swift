import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct SystemJunkView: View {
    let viewModel: SystemJunkViewModel
    let theme: FeatureTheme

    var body: some View {
        ZStack {
            FeatureBackground(theme: theme)
            content
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
        .environment(\.colorScheme, .dark)
        .animation(.smooth(duration: 0.35), value: viewModel.phase)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            JunkIdleView(theme: theme) { viewModel.startScan() }
        case .scanning:
            JunkScanningView(viewModel: viewModel, theme: theme)
        case .review where viewModel.results.isEmpty:
            JunkAllCleanView(theme: theme) { viewModel.reset() }
        case .review:
            JunkReviewView(viewModel: viewModel, theme: theme)
        case .cleaning:
            BusyView(theme: theme)
        case .finished(let report):
            CleanupCompletionView(report: report, theme: theme) { viewModel.reset() }
        }
    }
}
