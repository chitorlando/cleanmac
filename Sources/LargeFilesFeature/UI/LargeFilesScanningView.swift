import CleanMacUI
import SwiftUI

/// Progress while the home folder is walked or, above it, the folder the scan is limited to.
struct LargeFilesScanningView: View {
    @ObservedObject var viewModel: LargeFilesViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 28) {
            if let folder = viewModel.scope.folder {
                ScanScopePill(folder: folder, theme: theme) { viewModel.scanHome() }
                    .equatable()
            }
            ScanProgressView(
                progress: nil,
                value: viewModel.foundSize.formattedByteCount,
                caption: Text("found", bundle: .module, comment: "Caption below the size of large files found so far, as in “1.2 GB found”."),
                status: Text(
                    "\(viewModel.scannedFileCount) files analyzed",
                    bundle: .module,
                    comment: "Status shown while scanning. The argument is the number of files looked at so far."
                ),
                theme: theme,
                onCancel: { viewModel.stopScan() }
            )
        }
    }
}
