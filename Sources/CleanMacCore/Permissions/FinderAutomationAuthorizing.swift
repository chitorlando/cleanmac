/// Permission to send Apple Events to Finder, which CleanMac uses to move protected apps to
/// the Trash so they can be put back.
public protocol FinderAutomationAuthorizing: Sendable {
    /// Current status. Never asks the user.
    func status() -> PermissionStatus

    /// Asks the user once, if they haven't answered yet, and returns their answer.
    func requestAccess() async -> PermissionStatus
}
