import CleanMacCore
import CleanMacUI
import SwiftUI

/// Says that some folders inside the focused one couldn't be read, so it takes up more than
/// the map shows, with a way to give CleanMac Full Disk Access.
struct UnreadableFoldersNote: View {
    @Environment(\.permissionSettings) private var permissionSettings

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Label {
                Text(
                    "Some folders couldn’t be read and count as empty. Full Disk Access lets CleanMac read most of them.",
                    bundle: .module,
                    comment: "Note under the size of a folder of the disk map when some folders inside it couldn't be read."
                )
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Button {
                permissionSettings.open(.fullDiskAccess)
            } label: {
                Text("Open Privacy & Security", bundle: .module, comment: "Button that opens the Privacy & Security pane of System Settings.")
            }
            .buttonStyle(.borderless)
        }
    }
}
