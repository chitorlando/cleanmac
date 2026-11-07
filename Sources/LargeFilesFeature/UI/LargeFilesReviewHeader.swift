import CleanMacUI
import SwiftUI

/// Total size and number of large files found.
struct LargeFilesReviewHeader: View {
    let foundSize: Int64
    let foundCount: Int
    let theme: FeatureTheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(foundSize.formattedByteCount)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
            Text(
                "in \(foundCount) large files. Choose the ones you no longer need.",
                bundle: .module,
                comment: "Shown after the total size found, as in “12 GB in 40 large files”. The argument is the number of files."
            )
            .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
