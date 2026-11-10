import CleanMacUI
import SwiftUI

/// Marks the copy suggested to keep, which "Select duplicates" leaves unmarked.
struct KeepBadge: View {
    var body: some View {
        StatusBadge(
            Text("Keep", bundle: .module, comment: "Badge on the copy of a group of duplicates suggested to keep."),
            color: .green
        )
        .help(explanation)
        .accessibilityHint(explanation)
    }

    private var explanation: Text {
        Text(
            "Suggested copy to keep. Select Duplicates leaves it unmarked.",
            bundle: .module,
            comment: "Explains the badge on the copy suggested to keep. “Select Duplicates” is the checkbox that marks the duplicates."
        )
    }
}
