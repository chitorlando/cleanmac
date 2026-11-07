import CleanMacCore
import Foundation

/// Runs every job as root from one AppleScript process. macOS asks for the administrator
/// password at the first job and remembers it for the rest of the process, so the user
/// is asked once. Each job runs on its own, and the script reports one result per job.
public struct PrivilegedCommandRunner: PrivilegedCommandRunning {
    static let osascript = URL(filePath: "/usr/bin/osascript")

    /// Each job's command line arrives as an argument, so it is never interpreted as AppleScript.
    /// Error -128 means the user dismissed the password prompt: the remaining jobs are skipped.
    static let scriptLines = [
        "on run argv",
        "set recordEnd to character id 30",
        "set fieldEnd to character id 31",
        "set batchReport to \"\"",
        "set wasCancelled to false",
        "repeat with jobLine in argv",
        "if wasCancelled then",
        "set batchReport to batchReport & \"cancelled\" & recordEnd",
        "else",
        "try",
        "do shell script (contents of jobLine) with administrator privileges",
        "set batchReport to batchReport & \"ok\" & recordEnd",
        "on error errorText number errorNumber",
        "if errorNumber is -128 then",
        "set wasCancelled to true",
        "set batchReport to batchReport & \"cancelled\" & recordEnd",
        "else",
        "set batchReport to batchReport & \"failed\" & fieldEnd & my withoutSeparators(errorText) & recordEnd",
        "end if",
        "end try",
        "end if",
        "end repeat",
        "return batchReport",
        "end run",
        "on withoutSeparators(rawText)",
        "set AppleScript's text item delimiters to {character id 30, character id 31}",
        "set textParts to text items of rawText",
        "set AppleScript's text item delimiters to \" \"",
        "set cleanText to textParts as text",
        "set AppleScript's text item delimiters to \"\"",
        "return cleanText",
        "end withoutSeparators"
    ]

    /// AppleScript error number for "User canceled".
    private static let userCanceledCode = "(-128)"

    private let runner: any CommandRunning

    public init(runner: any CommandRunning = CommandRunner()) {
        self.runner = runner
    }

    public func run(_ jobs: [[ShellCommand]]) async throws -> [MaintenanceOutcome] {
        guard !jobs.isEmpty else { return [] }
        let jobLines = jobs.map { $0.map(\.commandLine).joined(separator: " && ") }
        let arguments = Self.scriptLines.flatMap { ["-e", $0] } + jobLines
        do {
            let output = try await runner.run(Self.osascript, arguments: arguments)
            return try PrivilegedBatchReport.outcomes(from: output, jobCount: jobs.count)
        } catch let failure as CommandFailure where failure.message.hasSuffix(Self.userCanceledCode) {
            throw MaintenanceError.authorizationCancelled
        }
    }
}
