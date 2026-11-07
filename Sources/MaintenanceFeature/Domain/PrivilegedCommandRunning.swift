import Foundation

/// Runs jobs as root behind a single administrator password prompt.
public protocol PrivilegedCommandRunning: Sendable {
    /// Runs every job, even after another one fails, and returns one outcome per job in order.
    /// A job's commands run in order and stop at the first failure.
    /// If the user dismisses the password prompt, the jobs that did not run end as
    /// `MaintenanceError.authorizationCancelled`. Throws only when the batch cannot run at all.
    func run(_ jobs: [[ShellCommand]]) async throws -> [MaintenanceOutcome]
}
