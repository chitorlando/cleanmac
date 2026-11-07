import Foundation

/// A command-line tool that finished with a non-zero exit status.
public struct CommandFailure: LocalizedError, Equatable, Sendable {
    public let status: Int32
    /// What the tool wrote to standard error, trimmed.
    public let message: String

    public init(status: Int32, message: String) {
        self.status = status
        self.message = message
    }

    public var errorDescription: String? {
        message.isEmpty ? "The command failed with exit status \(status)." : message
    }
}
