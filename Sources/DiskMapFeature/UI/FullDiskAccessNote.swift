import AppKit
import SwiftUI

/// Explains that some folders stay out of the map without Full Disk Access, with a way to grant it.
struct FullDiskAccessNote: View {
    private static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")

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

            if let url = Self.settingsURL {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Text("Open Privacy & Security", bundle: .module, comment: "Button that opens the Privacy & Security pane of System Settings.")
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(minWidth: 320, maxWidth: 460)
    }
}
