import CleanMacCore
import Foundation
import LargeFilesFeature
import Testing

@MainActor
struct LargeFilesSoundEffectsTests {
    private typealias Fixtures = LargeFileFixtures

    private let trip = Fixtures.file("trip.mov", megabytes: 2_000)

    private func makeModule(_ viewModel: LargeFilesViewModel) -> LargeFilesModule {
        LargeFilesModule(viewModel: viewModel, preferences: Preferences(storage: InMemoryPreferenceStorage()))
    }

    // MARK: Phases

    @Test func theEndOfAScanPlaysItsSound() {
        #expect(LargeFilesPhase.scanning.soundEffect(movingTo: .review) == .scanFinished)
    }

    @Test func aRemovalPlaysOnlyWhenItMovedFilesToTheTrash() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([trip.item])

        #expect(LargeFilesPhase.removing.soundEffect(movingTo: .finished(moved)) == .cleanupFinished)
        #expect(LargeFilesPhase.removing.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    /// Going back to the list keeps the files found, without scanning again.
    @Test func goingBackToTheListAfterARemovalPlaysNothing() {
        #expect(LargeFilesPhase.finished(CleanupReport()).soundEffect(movingTo: .review) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(LargeFilesPhase.intro.soundEffect(movingTo: .scanning) == nil)
        #expect(LargeFilesPhase.review.soundEffect(movingTo: .scanning) == nil)
        #expect(LargeFilesPhase.review.soundEffect(movingTo: .removing) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachScanAndRemovalTheUserStarts() async {
        let viewModel = LargeFilesViewModel(
            scanner: StubLargeFileScanner(events: [.found(trip)]),
            cleanupService: CleanupService(remover: RecordingRemover()),
            now: { Fixtures.now },
            calendar: Fixtures.calendar
        )
        let recorder = SoundEffectRecorder(makeModule(viewModel).soundEffects)

        await viewModel.startScan().value
        viewModel.toggle(trip)
        viewModel.requestRemoval()
        await viewModel.remove()?.value
        viewModel.done()

        #expect(recorder.recorded == [.scanFinished, .cleanupFinished])
    }
}
