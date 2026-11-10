import CleanMacUI
import SwiftUI

/// Marks a copy that shares its data with another file, so removing it frees little or no space.
struct CloneBadge: View {
    var body: some View {
        StatusBadge(
            Text("Clone", bundle: .module, comment: "Badge on a copy that is an APFS clone of another file."),
            color: .orange
        )
        .help(explanation)
        .accessibilityHint(explanation)
    }

    private var explanation: Text {
        Text(
            "This copy is an APFS clone: it shares its data with another file, so moving it to the Trash frees little or no space.",
            bundle: .module,
            comment: "Explains the badge on a copy that is an APFS clone of another file."
        )
    }
}
