import CleanMacUI
import SwiftUI

/// Progress while the home folder, or the folder chosen, is walked and the candidates are compared.
struct DuplicatesScanningView: View {
    @ObservedObject var viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        ScanProgressView(
            progress: nil,
            value: viewModel.progress.scannedFiles.formatted(),
            caption: Text("files analyzed", bundle: .module, comment: "Caption below the number of files looked at so far."),
            status: status,
            theme: theme,
            onCancel: { viewModel.stopScan() }
        )
    }

    private var status: Text {
        guard !viewModel.groups.isEmpty else {
            return Text("Looking for identical files…", bundle: .module, comment: "Status shown while scanning, before any duplicate is found.")
        }
        return Text(
            "\(viewModel.groups.count) groups of duplicates found",
            bundle: .module,
            comment: "Status shown while scanning. The argument is the number of groups of identical files found so far."
        )
    }
}
