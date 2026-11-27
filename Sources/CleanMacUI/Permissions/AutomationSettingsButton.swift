import CleanMacCore
import SwiftUI

/// Button that opens the Automation pane of System Settings, where the user lets CleanMac
/// control Finder.
public struct AutomationSettingsButton: View {
    @Environment(\.permissionSettings) private var permissionSettings

    public init() {}

    public var body: some View {
        Button {
            permissionSettings.open(.automation)
        } label: {
            Text("Open Automation Settings", bundle: .module, comment: "Button that opens the Automation pane of System Settings.")
        }
        .buttonStyle(.borderless)
    }
}
