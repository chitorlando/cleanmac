import CleanMacUI
import Foundation
import SwiftUI

/// Root screen of the feature. Shows the view that matches the current phase and, above it,
/// the folder the scan is limited to when it doesn't cover the whole home folder.
struct DuplicatesView: View {
    @ObservedObject var viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        FeatureScreen(theme: theme) {
            VStack(spacing: 16) {
                if let folder = folderOnScreen {
                    ScanScopePill(folder: folder, theme: theme) { viewModel.scanHome() }
                        .equatable()
                        .transition(.opacity)
                }
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .phaseTransition()
            }
            .padding(32)
        }
        .animation(.smooth(duration: 0.35), value: viewModel.phase)
        .animation(.smooth(duration: 0.35), value: viewModel.scope)
    }

    /// The folder the scan is limited to, on the screens that show a scan or what it found.
    /// A removal and its report show no folder, so nothing starts a scan over them.
    private var folderOnScreen: URL? {
        switch viewModel.phase {
        case .scanning, .review: viewModel.scope.folder
        case .intro, .removing, .finished: nil
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .intro:
            DuplicatesIntroView(theme: theme) { viewModel.startScan() }
        case .scanning:
            DuplicatesScanningView(viewModel: viewModel, theme: theme)
        case .review where viewModel.groups.isEmpty:
            DuplicatesNoneFoundView(
                wasStoppedEarly: viewModel.wasStoppedEarly,
                folder: viewModel.scope.folder,
                theme: theme
            ) {
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
