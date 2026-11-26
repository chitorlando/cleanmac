import CleanMacCore
import SwiftUI

/// Button that opens the Full Disk Access pane of System Settings, where the user lets CleanMac
/// reach what macOS keeps it away from.
public struct FullDiskAccessSettingsButton: View {
    @Environment(\.permissionSettings) private var permissionSettings

    public init() {}

    public var body: some View {
        Button {
            permissionSettings.open(.fullDiskAccess)
        } label: {
            Text("Open Full Disk Access Settings", bundle: .module, comment: "Button that opens the Full Disk Access pane of System Settings.")
        }
        .buttonStyle(.borderless)
    }
}
