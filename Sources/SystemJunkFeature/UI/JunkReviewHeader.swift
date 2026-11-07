import CleanMacUI
import SwiftUI

/// Summary of how much junk was found.
struct JunkReviewHeader: View {
    let foundSize: Int64
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 6) {
            Text(foundSize.formattedByteCount)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
            Text(
                "of junk found. Review what you want to clean.",
                bundle: .module,
                comment: "Shown below the total size of junk found, as in “1.2 GB of junk found”."
            )
            .foregroundStyle(.secondary)
        }
    }
}
