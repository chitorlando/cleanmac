import CleanMacUI
import SwiftUI

/// The Trash in the menu of the menu bar monitor: what it holds, and a button that empties it
/// once the user confirms it in the dialog that asks before erasing anything for good.
struct MenuBarTrashCard: View {
    @ObservedObject var trash: MenuBarTrash
    let theme: FeatureTheme

    var body: some View {
        MonitorCard(
            title: Text("Trash", bundle: .module, comment: "Title of the Trash section of the menu bar monitor."),
            symbolName: "trash",
            theme: theme
        ) {
            Button {
                trash.requestEmpty()
            } label: {
                Text("Empty Trash…", bundle: .module, comment: "Button of the menu bar monitor that asks before emptying the Trash.")
            }
            .buttonStyle(.borderless)
            .disabled(!trash.canEmpty)
        } content: {
            status
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .emptyTrashConfirmation(
            trashSize: trash.size,
            isPresented: trash.isConfirmingEmpty,
            onConfirm: { Task { await trash.empty() } },
            onDismiss: { trash.cancelEmpty() }
        )
    }

    @ViewBuilder
    private var status: some View {
        if trash.isEmptying {
            Text("Emptying the Trash…", bundle: .module, comment: "Shown in the menu bar monitor while Finder empties the Trash.")
        } else if trash.emptyingFailed {
            Text("The Trash couldn’t be emptied.", bundle: .module, comment: "Shown in the menu bar monitor when Finder couldn’t empty the Trash.")
        } else if trash.usage == .unreadable {
            Text(
                "Measuring the Trash needs Full Disk Access.",
                bundle: .module,
                comment: "Shown in the menu bar monitor when macOS keeps CleanMac out of the Trash, so its size is unknown."
            )
        } else if let size = trash.size {
            if size == 0 {
                Text("The Trash is empty.", bundle: .module, comment: "Shown in the menu bar monitor when the Trash holds nothing.")
            } else {
                Text(
                    "\(size.formattedByteCount) in the Trash",
                    bundle: .module,
                    comment: "What the Trash holds, in the menu bar monitor. The argument is a size, such as “1.2 GB”."
                )
            }
        } else {
            Text(verbatim: "—")
        }
    }
}
