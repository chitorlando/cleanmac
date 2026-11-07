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
}
