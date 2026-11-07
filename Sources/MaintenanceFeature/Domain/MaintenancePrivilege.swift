import Foundation

/// Who a maintenance task has to run as.
public enum MaintenancePrivilege: Sendable {
    /// Runs as the current user, without asking for anything.
    case user
    /// Runs as root after the user enters an administrator password.
    case administrator
}
