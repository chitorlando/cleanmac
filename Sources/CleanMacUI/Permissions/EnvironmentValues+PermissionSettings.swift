import CleanMacCore
import SwiftUI

private struct PermissionSettingsKey: EnvironmentKey {
    static let defaultValue: any PermissionSettingsOpening = SystemSettingsOpener()
}

public extension EnvironmentValues {
    /// Opens the panes of System Settings where the user grants CleanMac access.
    /// Previews and tests can replace it.
    var permissionSettings: any PermissionSettingsOpening {
        get { self[PermissionSettingsKey.self] }
        set { self[PermissionSettingsKey.self] = newValue }
    }
}
