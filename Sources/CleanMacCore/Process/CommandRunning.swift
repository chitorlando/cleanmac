import Foundation

/// Runs a command-line tool and waits for it to finish.
public protocol CommandRunning: Sendable {
    /// Throws `CommandFailure` when the tool exits with a non-zero status
    /// and `CancellationError` when the task is cancelled before it finishes.
    func run(_ executable: URL, arguments: [String]) async throws
}
