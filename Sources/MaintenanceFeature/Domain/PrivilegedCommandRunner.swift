import CleanMacCore
import Foundation

/// Asks macOS for an administrator password once through AppleScript and runs every command as root.
public struct PrivilegedCommandRunner: PrivilegedCommandRunning {
    static let osascript = URL(filePath: "/usr/bin/osascript")

    /// The command line arrives as an argument, so it is never interpreted as AppleScript.
    static let scriptLines = [
        "on run argv",
        "do shell script (item 1 of argv) with administrator privileges",
        "end run"
    ]

    /// AppleScript error number for "User canceled".
    private static let userCanceledCode = "(-128)"

    private let runner: any CommandRunning

    public init(runner: any CommandRunning = CommandRunner()) {
        self.runner = runner
    }

    public func run(_ commands: [ShellCommand]) async throws {
        guard !commands.isEmpty else { return }
        let commandLine = commands.map(\.commandLine).joined(separator: " && ")
        let arguments = Self.scriptLines.flatMap { ["-e", $0] } + [commandLine]
        do {
            try await runner.run(Self.osascript, arguments: arguments)
        } catch let failure as CommandFailure where failure.message.hasSuffix(Self.userCanceledCode) {
            throw MaintenanceError.authorizationCancelled
        }
    }
}
