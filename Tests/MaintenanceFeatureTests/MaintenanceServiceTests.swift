import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

struct MaintenanceServiceTests {
    private static let environment = MaintenanceEnvironment(spotlightVolumes: [URL(filePath: "/")])
    private static let quickLook = MaintenanceTaskKind.resetQuickLook.commands(in: environment)[0].executable

    private func outcomes(_ report: MaintenanceReport) -> [MaintenanceOutcome] {
        report.results.map(\.outcome)
    }

    @Test func runsUserTasksInTheChosenOrder() async {
        let runner = SpyCommandRunner()
        let service = MaintenanceService(
            runner: runner,
            privilegedRunner: SpyPrivilegedCommandRunner(),
            environment: Self.environment
        )

        let report = await service.run([.resetQuickLook, .rebuildLaunchServices])

        let expected = [MaintenanceTaskKind.resetQuickLook, .rebuildLaunchServices].flatMap { $0.commands(in: Self.environment) }
        #expect(await runner.invocations.map(\.executable) == expected.map(\.executable))
        #expect(report.results.map(\.task) == [.resetQuickLook, .rebuildLaunchServices])
        #expect(report.failures.isEmpty)
    }

    @Test func groupsAdministratorTasksIntoOneBatch() async {
        let privileged = SpyPrivilegedCommandRunner()
        let service = MaintenanceService(
            runner: SpyCommandRunner(),
            privilegedRunner: privileged,
            environment: Self.environment
        )

        let report = await service.run([.flushDNS, .resetQuickLook, .freeMemory, .reindexSpotlight])

        let expected = [MaintenanceTaskKind.flushDNS, .freeMemory, .reindexSpotlight].map { $0.commands(in: Self.environment) }
        #expect(await privileged.batches == [expected])
        #expect(report.results.map(\.task) == [.flushDNS, .resetQuickLook, .freeMemory, .reindexSpotlight])
    }

    @Test func skipsThePasswordPromptWithoutAdministratorTasks() async {
        let privileged = SpyPrivilegedCommandRunner()
        let service = MaintenanceService(
            runner: SpyCommandRunner(),
            privilegedRunner: privileged,
            environment: Self.environment
        )

        _ = await service.run([.resetQuickLook])

        #expect(await privileged.batches.isEmpty)
    }

    @Test func reportsFailuresAndKeepsGoing() async {
        let runner = SpyCommandRunner(failures: [Self.quickLook: CommandFailure(status: 1, message: "busy")])
        let service = MaintenanceService(
            runner: runner,
            privilegedRunner: SpyPrivilegedCommandRunner(),
            environment: Self.environment
        )

        let report = await service.run([.resetQuickLook, .rebuildLaunchServices])

        #expect(outcomes(report) == [.failed(.failed(message: "busy")), .succeeded])
    }

    @Test func givesEachAdministratorTaskItsOwnOutcome() async {
        let privileged = SpyPrivilegedCommandRunner(outcomes: [.failed(.failed(message: "busy")), .succeeded])
        let service = MaintenanceService(
            runner: SpyCommandRunner(),
            privilegedRunner: privileged,
            environment: Self.environment
        )

        let report = await service.run([.flushDNS, .resetQuickLook, .freeMemory])

        #expect(outcomes(report) == [.failed(.failed(message: "busy")), .succeeded, .succeeded])
    }

    @Test func sharesTheErrorWhenTheBatchCannotRun() async {
        let privileged = SpyPrivilegedCommandRunner(throwing: MaintenanceError.authorizationCancelled)
        let service = MaintenanceService(
            runner: SpyCommandRunner(),
            privilegedRunner: privileged,
            environment: Self.environment
        )

        let report = await service.run([.flushDNS, .resetQuickLook, .freeMemory])

        #expect(outcomes(report) == [
            .failed(.authorizationCancelled),
            .succeeded,
            .failed(.authorizationCancelled)
        ])
    }

    @Test func runsRepeatedTasksOnce() async {
        let runner = SpyCommandRunner()
        let service = MaintenanceService(
            runner: runner,
            privilegedRunner: SpyPrivilegedCommandRunner(),
            environment: Self.environment
        )

        let report = await service.run([.resetQuickLook, .resetQuickLook])

        #expect(await runner.invocations.count == 1)
        #expect(report.results.map(\.task) == [.resetQuickLook])
    }

    @Test func runsNothingOnceCancelled() async {
        let runner = SpyCommandRunner()
        let privileged = SpyPrivilegedCommandRunner()
        let service = MaintenanceService(
            runner: runner,
            privilegedRunner: privileged,
            environment: Self.environment
        )

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
        let service = MaintenanceService(
            runner: runner,
            privilegedRunner: SpyPrivilegedCommandRunner(),
            environment: Self.environment
        )

        let report = await service.run([.resetQuickLook])

        #expect(outcomes(report) == [.failed(.cancelled)])
    }
}
