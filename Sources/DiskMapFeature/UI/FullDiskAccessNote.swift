import CleanMacCore
import CleanMacUI
import SwiftUI

/// Explains that some folders stay out of the map without Full Disk Access, with a way to grant it.
struct FullDiskAccessNote: View {
    @Environment(\.permissionSettings) private var permissionSettings

    var body: some View {
        VStack(spacing: 8) {
            Label {
                Text(
                    "For a complete map, give CleanMac Full Disk Access. Without it, macOS keeps some folders, such as Mail or Messages, out of the map.",
                    bundle: .module,
                    comment: "Note on the disk map intro about the Full Disk Access permission."
                )
            } icon: {
                Image(systemName: "lock.shield")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            Button {
                permissionSettings.open(.fullDiskAccess)
            } label: {
                Text("Open Privacy & Security", bundle: .module, comment: "Button that opens the Privacy & Security pane of System Settings.")
            }
            .buttonStyle(.borderless)
        }
        .frame(minWidth: 320, maxWidth: 460)
    }
}
