import CleanMacCore
import DiskMapFeature
import Foundation
import Testing

@MainActor
struct DiskMapSoundEffectsTests {
    private typealias Fixtures = DiskMapFixtures

    private let item = CleanableItem(url: Fixtures.home.appending(path: "Movies/trip.mov"), size: 500)

    private func makeModule() -> (DiskMapModule, DiskMapViewModel) {
        let viewModel = DiskMapViewModel(
            scanner: StubDiskMapScanner(events: [.finished(Fixtures.map)]),
            cleanupService: CleanupService(remover: RecordingRemover()),
            policy: DiskMapRemovalPolicy(home: Fixtures.home)
        )
        return (DiskMapModule(viewModel: viewModel), viewModel)
    }

    // MARK: Phases

    @Test func theEndOfAScanPlaysItsSound() {
        #expect(DiskMapPhase.scanning.soundEffect(movingTo: .map) == .scanFinished)
    }

    @Test func aRemovalPlaysOnlyWhenItMovedItemsToTheTrash() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([item])

        #expect(DiskMapPhase.removing.soundEffect(movingTo: .finished(moved)) == .cleanupFinished)
        #expect(DiskMapPhase.removing.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    /// A stopped scan shows no map.
    @Test func stoppingAScanPlaysNothing() {
        #expect(DiskMapPhase.scanning.soundEffect(movingTo: .intro) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(DiskMapPhase.intro.soundEffect(movingTo: .scanning) == nil)
        #expect(DiskMapPhase.map.soundEffect(movingTo: .removing) == nil)
        #expect(DiskMapPhase.finished(CleanupReport()).soundEffect(movingTo: .map) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachScanTheUserStarts() async {
        let (module, viewModel) = makeModule()
        let recorder = SoundEffectRecorder(module.soundEffects)

        await viewModel.startScan().value
        await viewModel.startScan().value

        #expect(recorder.recorded == [.scanFinished, .scanFinished])
    }
}
