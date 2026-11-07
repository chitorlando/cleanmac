import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

struct MaintenanceServiceTests {
    private static let quickLook = MaintenanceTaskKind.resetQuickLook.commands[0].executable

    private func outcomes(_ report: MaintenanceReport) -> [MaintenanceOutcome] {
        report.results.map(\.outcome)
    }

    @Test func runsUserTasksInTheChosenOrder() async {
        let runner = SpyCommandRunner()
        let service = MaintenanceService(runner: runner, privilegedRunner: SpyPrivilegedCommandRunner())

        let report = await service.run([.resetQuickLook, .rebuildLaunchServices])

        let expected = [MaintenanceTaskKind.resetQuickLook, .rebuildLaunchServices].flatMap(\.commands)
        #expect(await runner.invocations.map(\.executable) == expected.map(\.executable))
        #expect(report.results.map(\.task) == [.resetQuickLook, .rebuildLaunchServices])
        #expect(report.failures.isEmpty)
    }

    @Test func groupsAdministratorTasksIntoOneBatch() async {
        let privileged = SpyPrivilegedCommandRunner()
        let service = MaintenanceService(runner: SpyCommandRunner(), privilegedRunner: privileged)

        let report = await service.run([.flushDNS, .resetQuickLook, .freeMemory, .reindexSpotlight])

        let expected = [MaintenanceTaskKind.flushDNS, .freeMemory, .reindexSpotlight].flatMap(\.commands)
        #expect(await privileged.batches == [expected])
        #expect(report.results.map(\.task) == [.flushDNS, .resetQuickLook, .freeMemory, .reindexSpotlight])
    }

    @Test func skipsThePasswordPromptWithoutAdministratorTasks() async {
        let privileged = SpyPrivilegedCommandRunner()
        let service = MaintenanceService(runner: SpyCommandRunner(), privilegedRunner: privileged)

        _ = await service.run([.resetQuickLook])

        #expect(await privileged.batches.isEmpty)
    }

    @Test func reportsFailuresAndKeepsGoing() async {
        let runner = SpyCommandRunner(failures: [Self.quickLook: CommandFailure(status: 1, message: "busy")])
        let service = MaintenanceService(runner: runner, privilegedRunner: SpyPrivilegedCommandRunner())

        let report = await service.run([.resetQuickLook, .rebuildLaunchServices])

        #expect(outcomes(report) == [.failed(.failed(message: "busy")), .succeeded])
    }

    @Test func failsEveryAdministratorTaskWhenThePromptIsDismissed() async {
        let privileged = SpyPrivilegedCommandRunner(throwing: MaintenanceError.authorizationCancelled)
        let service = MaintenanceService(runner: SpyCommandRunner(), privilegedRunner: privileged)

        let report = await service.run([.flushDNS, .resetQuickLook, .freeMemory])

        #expect(outcomes(report) == [
            .failed(.authorizationCancelled),
            .succeeded,
            .failed(.authorizationCancelled)
        ])
    }

    @Test func runsRepeatedTasksOnce() async {
        let runner = SpyCommandRunner()
        let service = MaintenanceService(runner: runner, privilegedRunner: SpyPrivilegedCommandRunner())

        let report = await service.run([.resetQuickLook, .resetQuickLook])

        #expect(await runner.invocations.count == 1)
        #expect(report.results.map(\.task) == [.resetQuickLook])
    }

    @Test func runsNothingOnceCancelled() async {
        let runner = SpyCommandRunner()
        let privileged = SpyPrivilegedCommandRunner()
        let service = MaintenanceService(runner: runner, privilegedRunner: privileged)

        let report = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await service.run([.flushDNS, .resetQuickLook])
        }.value

        #expect(outcomes(report) == [.failed(.cancelled), .failed(.cancelled)])
        #expect(await runner.invocations.isEmpty)
        #expect(await privileged.batches.isEmpty)
    }

    @Test func reportsCommandsInterruptedByCancellation() async {
        let runner = SpyCommandRunner(failures: [Self.quickLook: CancellationError()])
        let service = MaintenanceService(runner: runner, privilegedRunner: SpyPrivilegedCommandRunner())

        let report = await service.run([.resetQuickLook])

        #expect(outcomes(report) == [.failed(.cancelled)])
    }
}
