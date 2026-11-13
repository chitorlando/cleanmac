import SwiftUI

private struct PrivacySettingsKey: EnvironmentKey {
    static let defaultValue: any PrivacySettingsOpening = SystemPrivacySettingsOpener()
}

public extension EnvironmentValues {
    /// Opens the privacy panes of System Settings. Previews and tests can replace it.
    var privacySettings: any PrivacySettingsOpening {
        get { self[PrivacySettingsKey.self] }
        set { self[PrivacySettingsKey.self] = newValue }
    }
}
