import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct DiskMapView: View {
    @ObservedObject var viewModel: DiskMapViewModel
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
            DiskMapIntroView(theme: theme) { viewModel.startScan() }
        case .scanning:
            DiskMapScanningView(progress: viewModel.progress, theme: theme) { viewModel.stopScan() }
        case .map:
            DiskMapBrowserView(viewModel: viewModel, theme: theme)
        case .removing:
            BusyView(theme: theme)
        case .finished(let report):
            CleanupCompletionView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
