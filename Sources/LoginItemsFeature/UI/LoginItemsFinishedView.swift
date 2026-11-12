import CleanMacCore
import CleanMacUI
import SwiftUI

/// Result of a removal, reminding the user that removed agents stop at the next login.
struct LoginItemsFinishedView: View {
    let report: CleanupReport
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "checkmark.seal.fill",
                title: String(
                    localized: "\(report.removedCount) items moved to the Trash",
                    bundle: .module,
                    comment: "Title after removing login items. The argument is how many."
                ),
                subtitle: String(
                    localized: "They stop running at your next login. Put them back from the Trash if you need them again.",
                    bundle: .module,
                    comment: "Shown after removing login items, which keep running until the next login."
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
