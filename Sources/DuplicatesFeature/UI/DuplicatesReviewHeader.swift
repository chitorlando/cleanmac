import CleanMacUI
import SwiftUI

/// Space that keeping one copy of each group would free, and how many groups were found.
struct DuplicatesReviewHeader: View {
    let recoverableSize: Int64
    let groupCount: Int
    let theme: FeatureTheme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(recoverableSize.formattedByteCount)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
            Text(
                "can be freed from \(groupCount) groups of identical files.",
                bundle: .module,
                comment: "Shown after the space that can be freed, as in “3 GB can be freed from 12 groups of identical files”. The argument is the number of groups."
            )
            .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
