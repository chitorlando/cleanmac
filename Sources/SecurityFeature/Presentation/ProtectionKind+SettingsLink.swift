import Foundation

public extension ProtectionKind {
    /// Link that opens System Settings where the protection is turned on, or `nil` for System
    /// Integrity Protection, which only macOS Recovery can change.
    ///
    /// When System Settings doesn't know the part after “?”, it still opens the pane.
    var settingsURL: URL? {
        switch self {
        case .fileVault:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?FileVault")
        case .firewall:
            URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension?Firewall")
        case .gatekeeper:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?General")
        case .systemIntegrityProtection:
            nil
        case .automaticUpdates, .xprotect:
            URL(string: "x-apple.systempreferences:com.apple.preferences.softwareupdate")
        }
    }
}
