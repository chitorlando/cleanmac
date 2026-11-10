import CleanMacUI
import SwiftUI

/// Progress while the home folder is measured. The total isn't known, so the ring just spins.
struct DiskMapScanningView: View {
    let progress: DiskMapProgress
    let theme: FeatureTheme
    let onStop: () -> Void

    var body: some View {
        ScanProgressView(
            progress: nil,
            value: progress.byteCount.formattedByteCount,
            caption: Text("measured", bundle: .module, comment: "Caption below the space measured so far, as in “120 GB measured”."),
            status: Text(
                "\(progress.fileCount) files analyzed",
                bundle: .module,
                comment: "Status shown while measuring. The argument is the number of files looked at so far."
            ),
            theme: theme,
            onCancel: onStop
        )
    }
}
