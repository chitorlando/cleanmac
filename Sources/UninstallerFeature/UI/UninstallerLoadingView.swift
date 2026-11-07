import CleanMacUI
import SwiftUI

/// Progress while installed apps are found and measured.
struct UninstallerLoadingView: View {
    let viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        ScanProgressView(
            progress: viewModel.loadProgress,
            value: viewModel.analyzedCount.formatted(),
            caption: caption,
            status: Text("Analyzing installed apps…", bundle: .module, comment: "Status shown while the installed apps are measured."),
            theme: theme,
            onCancel: { viewModel.cancelLoading() }
        )
    }

    private var caption: Text {
        guard let discoveredCount = viewModel.discoveredCount else {
            return Text("apps analyzed", bundle: .module, comment: "Caption below the number of apps analyzed so far.")
        }
        return Text(
            "of \(discoveredCount) apps",
            bundle: .module,
            comment: "Caption below the number of apps analyzed so far, as in “12 of 52 apps”. The argument is the total."
        )
    }
}
