import CleanMacUI
import SwiftUI

/// Summary of how much browser cache was found.
struct PrivacyReviewHeader: View {
    let foundSize: Int64
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 6) {
            Text(foundSize.formattedByteCount)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
            Text(
                "of browser caches found. Review what you want to clear.",
                bundle: .module,
                comment: "Shown below the total size of browser caches found, as in “1.2 GB of browser caches found”."
            )
            .foregroundStyle(.secondary)
        }
    }
}
