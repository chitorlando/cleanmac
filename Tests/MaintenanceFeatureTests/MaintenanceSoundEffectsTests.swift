import CleanMacCore
import MaintenanceFeature
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct MaintenanceSoundEffectsTests {
    private func report(_ outcomes: [MaintenanceOutcome]) -> MaintenanceReport {
        MaintenanceReport(results: outcomes.map { MaintenanceTaskResult(task: .flushDNS, outcome: $0) })
    }

    // MARK: Phases

    @Test func aRunPlaysItsSoundWhenATaskSucceeded() {
        let partly = report([.failed(.failed(message: "No")), .succeeded])

        #expect(MaintenancePhase.running.soundEffect(movingTo: .finished(report([.succeeded]))) == .maintenanceFinished)
        #expect(MaintenancePhase.running.soundEffect(movingTo: .finished(partly)) == .maintenanceFinished)
    }

    /// Such as when the user didn't give the administrator password.
    @Test func aRunWhereEveryTaskFailedPlaysNothing() {
        let failed = report([.failed(.authorizationCancelled), .failed(.authorizationCancelled)])

        #expect(MaintenancePhase.running.soundEffect(movingTo: .finished(failed)) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(MaintenancePhase.choosing.soundEffect(movingTo: .running) == nil)
        #expect(MaintenancePhase.finished(report([.succeeded])).soundEffect(movingTo: .choosing) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachRun() async {
        let viewModel = MaintenanceViewModel(runner: SpyMaintenanceRunner())
        let recorder = SoundEffectRecorder(MaintenanceModule(viewModel: viewModel).soundEffects)

        viewModel.toggle(.resetQuickLook)
        await viewModel.run()?.value
        viewModel.done()
        viewModel.toggle(.flushDNS)
        await viewModel.run()?.value

        #expect(recorder.recorded == [.maintenanceFinished, .maintenanceFinished])
    }
}
