import Foundation

/// Runs a batch of commands as root behind a single administrator password prompt.
public protocol PrivilegedCommandRunning: Sendable {
    /// Runs the commands in order and stops at the first failure.
    /// Throws `MaintenanceError.authorizationCancelled` if the user dismisses the prompt.
    func run(_ commands: [ShellCommand]) async throws
}
