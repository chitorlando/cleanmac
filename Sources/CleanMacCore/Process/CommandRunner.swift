import Foundation

/// Runs a command-line tool as a subprocess without blocking any thread.
/// Standard error is drained while the tool runs, so a chatty tool never stalls on a full pipe,
/// and cancelling the task terminates the tool.
public struct CommandRunner: CommandRunning {
    public init() {}

    public func run(_ executable: URL, arguments: [String]) async throws {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        let errorPipe = Pipe()
        process.standardError = errorPipe

        let (terminations, continuation) = AsyncStream.makeStream(of: Int32.self)
        process.terminationHandler = { finished in
            continuation.yield(finished.terminationStatus)
            continuation.finish()
        }
        let launchable = LaunchableProcess(process)

        try await withTaskCancellationHandler {
            try launchable.launch()
            async let errorOutput = Self.readAll(errorPipe.fileHandleForReading)
            var status: Int32 = 0
            for await terminationStatus in terminations {
                status = terminationStatus
            }
            let message = await errorOutput
            try Task.checkCancellation()
            guard status == 0 else {
                throw CommandFailure(status: status, message: message)
            }
        } onCancel: {
            launchable.terminate()
        }
    }

    /// Reads until the tool closes the stream and returns the text, trimmed.
    private static func readAll(_ handle: FileHandle) async -> String {
        var bytes: [UInt8] = []
        do {
            for try await byte in handle.bytes {
                bytes.append(byte)
            }
        } catch {
            // Keep whatever was read before the stream failed.
        }
        return String(decoding: bytes, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
