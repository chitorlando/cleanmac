import Foundation

/// Runs a command-line tool as a subprocess without blocking any thread.
/// Both output streams are drained while the tool runs, so a chatty tool never stalls on a full pipe,
/// and cancelling the task terminates the tool.
public struct CommandRunner: CommandRunning {
    public init() {}

    @discardableResult
    public func run(_ executable: URL, arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        let (terminations, continuation) = AsyncStream.makeStream(of: Int32.self)
        process.terminationHandler = { finished in
            continuation.yield(finished.terminationStatus)
            continuation.finish()
        }
        let launchable = LaunchableProcess(process)

        return try await withTaskCancellationHandler {
            try launchable.launch()
            async let output = Self.readAll(outputPipe.fileHandleForReading)
            async let errorOutput = Self.readAll(errorPipe.fileHandleForReading)
            var status: Int32 = 0
            for await terminationStatus in terminations {
                status = terminationStatus
            }
            let (text, message) = await (output, errorOutput)
            try Task.checkCancellation()
            guard status == 0 else {
                throw CommandFailure(status: status, message: message.trimmed)
            }
            return text
        } onCancel: {
            launchable.terminate()
        }
    }

    /// Reads until the tool closes the stream and returns the text.
    /// Each stream gets its own dispatch thread: `FileHandle.bytes` reads every handle
    /// on one shared serial queue, so draining two pipes with it can deadlock.
    private static func readAll(_ handle: FileHandle) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let data = (try? handle.readToEnd()) ?? Data()
                continuation.resume(returning: String(decoding: data, as: UTF8.self))
            }
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
