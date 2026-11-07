import CleanMacCore
import CleanMacUI
import SwiftUI

/// Result of a cleanup.
struct JunkFinishedView: View {
    let report: CleanupReport
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "checkmark.seal.fill",
                title: title,
                subtitle: summary,
                theme: theme
            )
            if !report.failures.isEmpty {
                JunkFailureList(failures: report.failures)
            }
            Button(action: onDone) {
                Text("Done", bundle: .module, comment: "Button that closes a result screen.")
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: 560)
    }

    private var title: String {
        String(
            localized: "\(report.freedBytes.formattedByteCount) freed",
            bundle: .module,
            comment: "Title after a cleanup. The argument is a size, such as “1.2 GB”."
        )
    }

    private var summary: String {
        String(
            localized: "\(report.removedCount) items moved to the Trash. Empty it to reclaim the disk space.",
            bundle: .module,
            comment: "Summary after a cleanup. The argument is the number of items removed."
        )
    }
}
