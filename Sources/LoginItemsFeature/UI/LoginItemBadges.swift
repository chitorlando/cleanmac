import CleanMacUI
import SwiftUI

/// Flags an item whose program is gone, or that launchd ignores.
struct LoginItemBadges: View {
    let item: LoginItem

    var body: some View {
        HStack(spacing: 6) {
            if item.isOrphaned {
                StatusBadge(
                    Text("Orphaned", bundle: .module, comment: "Badge on a login item whose program no longer exists."),
                    color: .orange
                )
                .help(Text(
                    "Its program no longer exists. It’s probably left over from a deleted app.",
                    bundle: .module,
                    comment: "Tooltip of the Orphaned badge."
                ))
            }
            if item.job.isDisabled {
                StatusBadge(
                    Text("Disabled", bundle: .module, comment: "Badge on a login item that launchd ignores."),
                    color: .secondary
                )
            }
        }
    }
}
