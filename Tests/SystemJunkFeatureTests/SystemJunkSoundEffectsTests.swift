import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

@MainActor
struct SystemJunkSoundEffectsTests {
    private let item = CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/com.example.app"), size: 42)
    private let bin = CleanableItem(url: URL(filePath: "/Users/test/.Trash", directoryHint: .isDirectory), size: 300)

    private func makeViewModel() -> SystemJunkViewModel {
        SystemJunkViewModel(
            scanService: JunkScanService(scanners: [StubJunkScanner(category: .userCaches, items: [item])]),
            cleanupService: CleanupService(remover: RecordingRemover()),
            trashEmptying: TrashEmptyingService(emptier: RecordingTrashEmptier()),
            runningApps: FakeRunningApps(),
            cacheUsage: BrowserCacheUsage(library: URL(filePath: "/Users/test/Library"))
        )
    }

    // MARK: Phases

    @Test func theEndOfAScanPlaysItsSound() {
        #expect(SystemJunkPhase.scanning.soundEffect(movingTo: .review) == .scanFinished)
    }

    @Test func theEndOfACleanupPlaysWhatItDid() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([item])
        let emptied = await TrashEmptyingService(emptier: RecordingTrashEmptier()).empty([bin])

        #expect(SystemJunkPhase.cleaning.soundEffect(movingTo: .finished(moved)) == .cleanupFinished)
        #expect(SystemJunkPhase.cleaning.soundEffect(movingTo: .finished(emptied)) == .trashEmptied)
        #expect(SystemJunkPhase.cleaning.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(SystemJunkPhase.idle.soundEffect(movingTo: .scanning) == nil)
        #expect(SystemJunkPhase.scanning.soundEffect(movingTo: .idle) == nil)
        #expect(SystemJunkPhase.review.soundEffect(movingTo: .cleaning) == nil)
        #expect(SystemJunkPhase.finished(CleanupReport()).soundEffect(movingTo: .idle) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachScanAndCleanupTheUserStarts() async {
        let viewModel = makeViewModel()
        let recorder = SoundEffectRecorder(SystemJunkModule(viewModel: viewModel).soundEffects)

        await viewModel.startScan().value
        viewModel.requestClean()
        await viewModel.clean()?.value
        viewModel.reset()
        await viewModel.startScan().value

        #expect(recorder.recorded == [.scanFinished, .cleanupFinished, .scanFinished])
    }

    /// The review on screen is checked again, such as for the browsers that are open, without
    /// any scan or cleanup ending.
    @Test func updatingTheReviewPlaysNothing() async {
        let viewModel = makeViewModel()
        await viewModel.startScan().value
        let recorder = SoundEffectRecorder(SystemJunkModule(viewModel: viewModel).soundEffects)

        viewModel.refreshOpenApps()
        viewModel.toggle(item)
        viewModel.requestClean()
        viewModel.cancelClean()

        #expect(recorder.recorded.isEmpty)
    }
}
