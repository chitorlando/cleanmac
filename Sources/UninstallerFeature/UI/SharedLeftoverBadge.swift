import CleanMacUI
import SwiftUI

/// Marks a leftover that another installed copy of the app also uses.
struct SharedLeftoverBadge: View {
    var body: some View {
        StatusBadge(
            Text("Shared with another copy", bundle: .module, comment: "Badge on a file that another copy of the same app also uses."),
            color: .orange
        )
        .help(explanation)
        .accessibilityHint(explanation)
    }

    private var explanation: Text {
        Text(
            "Another installed copy of this app uses this item too, so it isn’t selected automatically. Select it only if you are removing every copy.",
            bundle: .module,
            comment: "Explains why a shared file is not selected when the app is."
        )
    }
}
