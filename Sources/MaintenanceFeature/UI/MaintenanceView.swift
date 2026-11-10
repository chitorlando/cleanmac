import CleanMacUI
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase.
struct MaintenanceView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
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
        case .choosing:
            MaintenanceChoosingView(viewModel: viewModel, theme: theme)
        case .running:
            MaintenanceRunningView(requiresAdministrator: viewModel.requiresAdministrator, theme: theme)
        case .finished(let report):
            MaintenanceFinishedView(report: report, theme: theme) { viewModel.done() }
        }
    }
}
