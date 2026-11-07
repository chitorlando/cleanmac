import CleanMacCore
@testable import MaintenanceFeature
import Foundation
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct MaintenanceViewModelTests {
    @Test func startsChoosingWithNothingSelected() {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())

        #expect(viewModel.phase == .choosing)
        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func togglesSingleTasks() {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())

        viewModel.toggle(.flushDNS)
        viewModel.toggle(.resetQuickLook)
        viewModel.toggle(.flushDNS)

        #expect(viewModel.selection == [.resetQuickLook])
        #expect(viewModel.allSelectionState == .some)
    }

    @Test func toggleAllSelectsEverythingThenClears() {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())
        viewModel.toggle(.freeMemory)

        viewModel.toggleAll()
        #expect(viewModel.allSelectionState == .all)
        #expect(viewModel.selectedCount == MaintenanceTaskKind.allCases.count)

        viewModel.toggleAll()
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func requiresAdministratorOnlyForAdministratorTasks() {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())

        viewModel.toggle(.resetQuickLook)
        viewModel.toggle(.rebuildLaunchServices)
        #expect(!viewModel.requiresAdministrator)

        viewModel.toggle(.reindexSpotlight)
        #expect(viewModel.requiresAdministrator)
    }

    @Test func runsChosenTasksInCatalogOrder() async {
        let runner = SpyMaintenanceRunner()
        let viewModel = MaintenanceViewModel(runner: runner)
        viewModel.toggle(.resetQuickLook)
        viewModel.toggle(.flushDNS)
        viewModel.toggle(.reindexSpotlight)

        await viewModel.run()?.value

        #expect(await runner.requests == [[.flushDNS, .reindexSpotlight, .resetQuickLook]])
    }

    @Test func goesThroughRunningToFinished() async {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())
        viewModel.toggle(.freeMemory)

        let task = viewModel.run()
        #expect(viewModel.phase == .running)
        await task?.value

        let expected = MaintenanceReport(results: [MaintenanceTaskResult(task: .freeMemory, outcome: .succeeded)])
        #expect(viewModel.phase == .finished(expected))
    }

    @Test func doesNotRunWithoutSelection() async {
        let runner = SpyMaintenanceRunner()
        let viewModel = MaintenanceViewModel(runner: runner)

        #expect(viewModel.run() == nil)
        #expect(viewModel.phase == .choosing)
        #expect(await runner.requests.isEmpty)
    }

    @Test func ignoresSelectionChangesWhileRunning() async {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())
        viewModel.toggle(.freeMemory)

        let task = viewModel.run()
        viewModel.toggle(.flushDNS)
        viewModel.toggleAll()
        await task?.value

        #expect(viewModel.selection == [.freeMemory])
    }

    @Test func doneStartsOverWithNothingSelected() async {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())
        viewModel.toggle(.freeMemory)
        await viewModel.run()?.value

        viewModel.done()

        #expect(viewModel.phase == .choosing)
        #expect(!viewModel.hasSelection)
    }

    @Test func keepsThePhaseWhenTheRunIsCancelled() async {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner(waitsForCancellation: true))
        viewModel.toggle(.freeMemory)

        let task = viewModel.run()
        task?.cancel()
        await task?.value

        #expect(viewModel.phase == .running)
    }
}
