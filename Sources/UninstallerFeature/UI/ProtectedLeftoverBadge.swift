import CleanMacUI
import SwiftUI

/// Marks a leftover that macOS protects, so moving it to the Trash may need Full Disk Access.
struct ProtectedLeftoverBadge: View {
    var body: some View {
        StatusBadge(
            Text("Protected by macOS", bundle: .module, comment: "Badge on an app's container, which macOS protects."),
            color: .cyan
        )
        .help(explanation)
        .accessibilityHint(explanation)
    }

    private var explanation: Text {
        Text(
            "macOS protects app containers. If CleanMac can’t move this item to the Trash, give it Full Disk Access or move the item yourself in Finder.",
            bundle: .module,
            comment: "Explains the badge on an app's container that macOS protects."
        )
    }
}
