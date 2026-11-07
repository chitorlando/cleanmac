import Foundation

/// A tool to run together with its arguments.
public struct ShellCommand: Hashable, Sendable {
    public let executable: URL
    public let arguments: [String]

    public init(_ executablePath: String, _ arguments: String...) {
        self.executable = URL(filePath: executablePath)
        self.arguments = arguments
    }

    /// The command as one line for a POSIX shell, with every word quoted as needed.
    public var commandLine: String {
        ([executable.path] + arguments).map(\.shellQuoted).joined(separator: " ")
    }
}
