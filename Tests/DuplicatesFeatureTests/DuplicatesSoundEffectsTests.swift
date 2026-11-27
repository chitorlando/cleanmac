import CleanMacCore
import DuplicatesFeature
import Foundation
import Testing

@MainActor
struct DuplicatesSoundEffectsTests {
    private let copy = CleanableItem(url: URL(filePath: "/Users/test/Downloads/photo copy.jpg"), size: 5_000_000)

    // MARK: Phases

    @Test func theEndOfAScanPlaysItsSound() {
        #expect(DuplicatesPhase.scanning.soundEffect(movingTo: .review) == .scanFinished)
    }

    @Test func aRemovalPlaysOnlyWhenItMovedCopiesToTheTrash() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([copy])

        #expect(DuplicatesPhase.removing.soundEffect(movingTo: .finished(moved)) == .cleanupFinished)
        #expect(DuplicatesPhase.removing.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    /// Going back to the list keeps the groups found, without scanning again.
    @Test func goingBackToTheListAfterARemovalPlaysNothing() {
        #expect(DuplicatesPhase.finished(CleanupReport()).soundEffect(movingTo: .review) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(DuplicatesPhase.intro.soundEffect(movingTo: .scanning) == nil)
        #expect(DuplicatesPhase.review.soundEffect(movingTo: .scanning) == nil)
        #expect(DuplicatesPhase.review.soundEffect(movingTo: .removing) == nil)
    }

    // MARK: Module

    /// Also when the scan found nothing: it still ended.
    @Test func playsOnceForEachScanTheUserStarts() async {
        let viewModel = DuplicatesViewModel(
            scanner: StubDuplicateScanner(events: []),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        let module = DuplicatesModule(viewModel: viewModel, preferences: Preferences(storage: InMemoryPreferenceStorage()))
        let recorder = SoundEffectRecorder(module.soundEffects)

        await viewModel.startScan().value
        await viewModel.startScan().value

        #expect(recorder.recorded == [.scanFinished, .scanFinished])
    }
}
