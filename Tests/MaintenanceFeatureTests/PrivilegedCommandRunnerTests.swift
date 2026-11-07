import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

struct PrivilegedCommandRunnerTests {
    private let commands = [
        ShellCommand("/usr/bin/first", "-a"),
        ShellCommand("/usr/bin/second", "two words")
    ]

    @Test func runsTheWholeBatchInOneAppleScriptCall() async throws {
        let spy = SpyCommandRunner()

        try await PrivilegedCommandRunner(runner: spy).run(commands)

        let invocations = await spy.invocations
        #expect(invocations.count == 1)
        #expect(invocations.first?.executable == PrivilegedCommandRunner.osascript)
    }

    @Test func passesTheQuotedCommandLineAsAnArgument() async throws {
        let spy = SpyCommandRunner()

        try await PrivilegedCommandRunner(runner: spy).run(commands)

        let arguments = try #require(await spy.invocations.first?.arguments)
        #expect(arguments.last == "/usr/bin/first -a && /usr/bin/second 'two words'")
        #expect(!arguments.dropLast().contains { $0.contains("/usr/bin/first") })
    }

    @Test func keepsTheScriptFixed() async throws {
        let spy = SpyCommandRunner()

        try await PrivilegedCommandRunner(runner: spy).run(commands)

        let arguments = try #require(await spy.invocations.first?.arguments)
        let script = stride(from: 1, to: arguments.count - 1, by: 2).map { arguments[$0] }
        #expect(script == PrivilegedCommandRunner.scriptLines)
    }

    @Test func doesNothingWithoutCommands() async throws {
        let spy = SpyCommandRunner()

        try await PrivilegedCommandRunner(runner: spy).run([])

        #expect(await spy.invocations.isEmpty)
    }

    @Test func reportsADismissedPasswordPrompt() async {
        let canceled = CommandFailure(status: 1, message: "execution error: User canceled. (-128)")
        let spy = SpyCommandRunner(failures: [PrivilegedCommandRunner.osascript: canceled])

        await #expect(throws: MaintenanceError.authorizationCancelled) {
            try await PrivilegedCommandRunner(runner: spy).run(commands)
        }
    }

    @Test func rethrowsOtherFailures() async {
        let failure = CommandFailure(status: 1, message: "execution error: boom (1)")
        let spy = SpyCommandRunner(failures: [PrivilegedCommandRunner.osascript: failure])

        await #expect(throws: failure) {
            try await PrivilegedCommandRunner(runner: spy).run(commands)
        }
    }
}
