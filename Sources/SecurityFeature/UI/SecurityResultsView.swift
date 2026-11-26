import CleanMacUI
import SwiftUI

/// What the review found, one card for each part, with the next step for each finding.
struct SecurityResultsView: View {
    let report: SecurityReport
    let theme: FeatureTheme
    let onReviewAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            SecurityResultsHeader(attentionCount: report.attentionCount)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ProtectionsCard(checks: report.protections)
                    AppsCard(checkedCount: report.apps.count, apps: report.appsNeedingAttention)
                }
            }
            .scrollIndicators(.never)
            ActionBar(
                secondaryTitle: Text("Review Again", bundle: .module, comment: "Button that runs the security review again."),
                primaryTitle: Text("Done", bundle: .module, comment: "Button that closes the results of the security review."),
                theme: theme,
                onSecondary: onReviewAgain,
                onPrimary: onDone
            )
        }
        .frame(maxWidth: 820)
    }
}
