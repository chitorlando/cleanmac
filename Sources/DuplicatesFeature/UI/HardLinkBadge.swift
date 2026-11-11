import CleanMacUI
import SwiftUI

/// Marks a copy whose file has another name on the disk, so removing it frees no space.
struct HardLinkBadge: View {
    var body: some View {
        StatusBadge(
            Text("Hard link", bundle: .module, comment: "Badge on a copy whose file has other names on the disk, its hard links."),
            color: .orange
        )
        .help(explanation)
        .accessibilityHint(explanation)
    }

    private var explanation: Text {
        Text(
            "This file has another name elsewhere on the disk, so moving this one to the Trash frees no space.",
            bundle: .module,
            comment: "Explains the badge on a copy whose file has other names on the disk, its hard links."
        )
    }
}
