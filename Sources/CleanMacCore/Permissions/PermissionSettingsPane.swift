import Foundation

/// A pane of Privacy & Security in System Settings.
public enum PermissionSettingsPane: CaseIterable, Sendable {
    case fullDiskAccess
    case automation

    /// Link that opens System Settings on the pane.
    public var url: URL {
        switch self {
        case .fullDiskAccess:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        case .automation:
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        }
    }
}
