import Foundation

/// Runs a command-line tool as a subprocess and waits for it without blocking any thread.
public struct CommandRunner: Sendable {
    public init() {}

    /// Throws `CommandFailure` with the tool's standard error when it exits with a non-zero status.
    public func run(_ executable: URL, arguments: [String]) async throws {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        let errorPipe = Pipe()
        process.standardError = errorPipe
        let errorOutput = errorPipe.fileHandleForReading

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            process.terminationHandler = { finished in
                let status = finished.terminationStatus
                guard status != 0 else {
                    continuation.resume()
                    return
                }
                let data = errorOutput.readDataToEndOfFile()
                let message = String(decoding: data, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(throwing: CommandFailure(status: status, message: message))
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
