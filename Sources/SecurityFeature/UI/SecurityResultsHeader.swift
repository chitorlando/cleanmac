import SwiftUI

/// Title of the results with how many findings need the user's attention.
struct SecurityResultsHeader: View {
    let attentionCount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Security", bundle: .module, comment: "Feature name in the sidebar.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)
                summary
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var summary: Text {
        guard attentionCount > 0 else {
            return Text("Nothing needs your attention.", bundle: .module, comment: "Summary of a security review that found nothing to look at.")
        }
        return Text(
            "\(attentionCount) things need your attention.",
            bundle: .module,
            comment: "Summary of a security review. The argument is how many findings the user should look at."
        )
    }
}
