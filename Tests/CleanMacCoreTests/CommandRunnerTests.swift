@testable import CleanMacCore
import Foundation
import Testing

struct CommandRunnerTests {
    private let shell = URL(filePath: "/bin/sh")

    @Test func finishesWhenTheCommandSucceeds() async throws {
        try await CommandRunner().run(shell, arguments: ["-c", "exit 0"])
    }

    @Test func throwsStatusAndStandardErrorOnFailure() async {
        await #expect(throws: CommandFailure(status: 3, message: "boom")) {
            try await CommandRunner().run(shell, arguments: ["-c", "echo boom >&2; exit 3"])
        }
    }

    @Test func describesFailuresWithoutOutputByTheirStatus() {
        let failure = CommandFailure(status: 7, message: "")

        #expect(failure.errorDescription == "The command failed with exit status 7.")
    }

    @Test func throwsWhenTheExecutableIsMissing() async {
        await #expect(throws: (any Error).self) {
            try await CommandRunner().run(URL(filePath: "/nonexistent/tool"), arguments: [])
        }
    }

    @Test func drainsLargeErrorOutputWithoutStalling() async {
        let script = "head -c 150000 /dev/zero | tr '\\0' x >&2; exit 3"

        await #expect {
            try await CommandRunner().run(shell, arguments: ["-c", script])
        } throws: { error in
            let failure = error as? CommandFailure
            return failure?.status == 3 && failure?.message.count == 150_000
        }
    }

    @Test func terminatesTheCommandWhenCancelled() async {
        let runner = CommandRunner()
        let task = Task {
            try await runner.run(shell, arguments: ["-c", "sleep 30"])
        }
        try? await Task.sleep(for: .milliseconds(200))
        let start = ContinuousClock.now

        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(ContinuousClock.now - start < .seconds(5))
    }

    @Test func doesNotLaunchWhenAlreadyCancelled() async {
        let marker = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let task = Task { [shell] in
            withUnsafeCurrentTask { $0?.cancel() }
            try await CommandRunner().run(shell, arguments: ["-c", "touch \"$0\"", marker.path])
        }

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(!FileManager.default.fileExists(atPath: marker.path))
    }
}
