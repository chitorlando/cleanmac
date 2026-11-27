import CleanMacCore
import SwiftUI

/// Result of a cleanup: space freed, items moved or the Trash emptied, and anything that failed.
///
/// The space freed counts up below a badge whose checkmark draws itself, with a burst around
/// it when everything went.
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
            SuccessHeader(subtitle: report.summary, theme: theme, celebrates: report.isCompleteSuccess) {
                CountUpText(report.freedBytes) { freedBytes in
                    String(
                        localized: "\(freedBytes.formattedByteCount) freed",
                        bundle: .module,
                        comment: "Title after a cleanup. The argument is a size, such as “1.2 GB”."
                    )
                }
            }
            if !report.failures.isEmpty {
                CleanupFailureList(failures: report.failures)
            }
            DoneButton(theme: theme, action: onDone)
        }
        .frame(maxWidth: 560)
    }
}
