import CleanMacCore
import CleanMacUI
import SwiftUI

/// Result of a cleanup, reminding the user that browsers rebuild their caches.
struct PrivacyFinishedView: View {
    let report: CleanupReport
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "checkmark.seal.fill",
                title: String(
                    localized: "\(report.freedBytes.formattedByteCount) cleared",
                    bundle: .module,
                    comment: "Title after clearing browser caches. The argument is a size, such as “1.2 GB”."
                ),
                subtitle: String(
                    localized: "The caches are in the Trash. Your browsers rebuild them when they need them.",
                    bundle: .module,
                    comment: "Shown after clearing browser caches."
                ),
                theme: theme
            )
            if !report.failures.isEmpty {
                CleanupFailureList(failures: report.failures)
            }
            DoneButton(theme: theme, action: onDone)
        }
        .frame(maxWidth: 560)
    }
}
