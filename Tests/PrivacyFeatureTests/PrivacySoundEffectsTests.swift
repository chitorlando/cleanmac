import CleanMacCore
import Foundation
import PrivacyFeature
import Testing

@MainActor
struct PrivacySoundEffectsTests {
    private let chrome = browserCaches("Google Chrome", bundleID: "com.google.Chrome", items: ["a": 300])
    private let cache = CleanableItem(url: URL(filePath: "/Users/test/Library/Caches/Google/Chrome"), size: 300)

    // MARK: Phases

    @Test func theEndOfAScanPlaysItsSound() {
        #expect(PrivacyPhase.scanning.soundEffect(movingTo: .review) == .scanFinished)
    }

    @Test func aCleanupPlaysOnlyWhenItMovedCachesToTheTrash() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([cache])

        #expect(PrivacyPhase.cleaning.soundEffect(movingTo: .finished(moved)) == .cleanupFinished)
        #expect(PrivacyPhase.cleaning.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(PrivacyPhase.intro.soundEffect(movingTo: .scanning) == nil)
        #expect(PrivacyPhase.scanning.soundEffect(movingTo: .intro) == nil)
        #expect(PrivacyPhase.review.soundEffect(movingTo: .cleaning) == nil)
        #expect(PrivacyPhase.finished(CleanupReport()).soundEffect(movingTo: .intro) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachScanAndCleanupTheUserStarts() async {
        let viewModel = PrivacyViewModel(
            scanner: StubBrowserCacheScanner(results: [chrome]),
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        let recorder = SoundEffectRecorder(PrivacyModule(viewModel: viewModel).soundEffects)

        await viewModel.startScan().value
        viewModel.refreshRunningBrowsers()
        viewModel.requestClean()
        await viewModel.clean()?.value
        viewModel.done()

        #expect(recorder.recorded == [.scanFinished, .cleanupFinished])
    }
}
