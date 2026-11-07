import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

struct PrivilegedCommandRunnerTests {
    private static let record = String(PrivilegedBatchReport.recordSeparator)
    private static let field = String(PrivilegedBatchReport.fieldSeparator)

    private let jobs = [
        [ShellCommand("/usr/bin/first", "-a"), ShellCommand("/usr/bin/second", "two words")],
        [ShellCommand("/usr/bin/third")]
    ]

    private func spy(answering records: [String]) -> SpyCommandRunner {
        let output = records.map { $0 + Self.record }.joined() + "\n"
        return SpyCommandRunner(outputs: [PrivilegedCommandRunner.osascript: output])
    }

    @Test func runsEveryJobFromOneAppleScriptCall() async throws {
        let spy = spy(answering: ["ok", "ok"])

        _ = try await PrivilegedCommandRunner(runner: spy).run(jobs)

        let invocations = await spy.invocations
        #expect(invocations.count == 1)
        #expect(invocations.first?.executable == PrivilegedCommandRunner.osascript)
    }

    @Test func passesOneQuotedCommandLinePerJobAsArguments() async throws {
        let spy = spy(answering: ["ok", "ok"])

        _ = try await PrivilegedCommandRunner(runner: spy).run(jobs)

        let arguments = try #require(await spy.invocations.first?.arguments)
        let scriptArgumentCount = PrivilegedCommandRunner.scriptLines.count * 2
        #expect(Array(arguments.dropFirst(scriptArgumentCount)) == [
            "/usr/bin/first -a && /usr/bin/second 'two words'",
            "/usr/bin/third"
        ])
    }

    @Test func keepsTheScriptFixed() async throws {
        let spy = spy(answering: ["ok", "ok"])

        _ = try await PrivilegedCommandRunner(runner: spy).run(jobs)

        let arguments = try #require(await spy.invocations.first?.arguments)
        let scriptArguments = arguments.prefix(PrivilegedCommandRunner.scriptLines.count * 2)
        #expect(scriptArguments.enumerated().allSatisfy { index, argument in
            index.isMultiple(of: 2) ? argument == "-e" : true
        })
        #expect(stride(from: 1, to: scriptArguments.count, by: 2).map { arguments[$0] }
            == PrivilegedCommandRunner.scriptLines)
    }

    @Test func reportsEachJobSeparately() async throws {
        let spy = spy(answering: ["failed" + Self.field + "busy", "ok"])

        let outcomes = try await PrivilegedCommandRunner(runner: spy).run(jobs)

        #expect(outcomes == [.failed(.failed(message: "busy")), .succeeded])
    }

    @Test func reportsJobsSkippedByADismissedPrompt() async throws {
        let spy = spy(answering: ["cancelled", "cancelled"])

        let outcomes = try await PrivilegedCommandRunner(runner: spy).run(jobs)

        #expect(outcomes == [.failed(.authorizationCancelled), .failed(.authorizationCancelled)])
    }

    @Test func doesNothingWithoutJobs() async throws {
        let spy = SpyCommandRunner()

        #expect(try await PrivilegedCommandRunner(runner: spy).run([]).isEmpty)
        #expect(await spy.invocations.isEmpty)
    }

    @Test func mapsAScriptLevelCancellation() async {
        let canceled = CommandFailure(status: 1, message: "execution error: User canceled. (-128)")
        let spy = SpyCommandRunner(failures: [PrivilegedCommandRunner.osascript: canceled])

        await #expect(throws: MaintenanceError.authorizationCancelled) {
            try await PrivilegedCommandRunner(runner: spy).run(jobs)
        }
    }

    @Test func rethrowsOtherScriptFailures() async {
        let failure = CommandFailure(status: 1, message: "syntax error (-2741)")
        let spy = SpyCommandRunner(failures: [PrivilegedCommandRunner.osascript: failure])

        await #expect(throws: failure) {
            try await PrivilegedCommandRunner(runner: spy).run(jobs)
        }
    }

    @Test func rejectsUnreadableOutput() async {
        let spy = spy(answering: ["ok"])

        await #expect(throws: MaintenanceError.unreadableResult) {
            try await PrivilegedCommandRunner(runner: spy).run(jobs)
        }
    }
}
