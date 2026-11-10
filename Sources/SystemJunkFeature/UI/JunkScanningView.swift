import CleanMacUI
import SwiftUI

/// Progress while the junk scanners run.
struct JunkScanningView: View {
    @ObservedObject var viewModel: SystemJunkViewModel
    let theme: FeatureTheme

    var body: some View {
        ScanProgressView(
            progress: viewModel.scanProgress,
            value: viewModel.foundSize.formattedByteCount,
            caption: Text("found", bundle: .module, comment: "Caption below the amount of junk found so far, as in “1.2 GB found”."),
            status: Text("Analyzing your Mac…", bundle: .module, comment: "Status shown while scanning."),
            theme: theme,
            onCancel: { viewModel.cancelScan() }
        )
    }
}
