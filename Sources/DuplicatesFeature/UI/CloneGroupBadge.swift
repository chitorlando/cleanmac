import CleanMacUI
import SwiftUI

/// Shown in the list instead of the space of a group whose copies all share the same data.
struct CloneGroupBadge: View {
    var body: some View {
        StatusBadge(
            Text("Clones", bundle: .module, comment: "Badge on a group of duplicates whose copies all share the same data on disk."),
            color: .orange
        )
        .help(explanation)
        .accessibilityHint(explanation)
    }

    private var explanation: Text {
        Text(
            "These copies share the same data on disk, so removing them frees no space.",
            bundle: .module,
            comment: "Explains why a group made only of APFS clones can free no space."
        )
    }
}
