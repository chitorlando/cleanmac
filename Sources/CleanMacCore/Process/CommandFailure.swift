import Foundation

/// A command-line tool that finished with a non-zero exit status.
public struct CommandFailure: LocalizedError, Equatable, Sendable {
    public let status: Int32
    /// What the tool wrote to standard error, trimmed.
    public let message: String
    /// What the tool wrote to standard output, as it wrote it. Some tools report a state
    /// there and tell it apart with their exit status, such as `spctl --status`.
    public let output: String

    public init(status: Int32, message: String, output: String = "") {
        self.status = status
        self.message = message
        self.output = output
    }

    public var errorDescription: String? {
        message.isEmpty ? "The command failed with exit status \(status)." : message
    }
}
