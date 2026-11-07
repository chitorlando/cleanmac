import CleanMacCore
import SwiftUI

/// Result of a cleanup: space freed, items moved and anything that failed.
public struct CleanupCompletionView: View {
    private let report: CleanupReport
    private let theme: FeatureTheme
    private let onDone: () -> Void

    public init(report: CleanupReport, theme: FeatureTheme, onDone: @escaping () -> Void) {
        self.report = report
        self.theme = theme
        self.onDone = onDone
    }

    public var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "checkmark.seal.fill",
                title: title,
                subtitle: summary,
                theme: theme
            )
            if !report.failures.isEmpty {
                CleanupFailureList(failures: report.failures)
            }
            DoneButton(theme: theme, action: onDone)
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
