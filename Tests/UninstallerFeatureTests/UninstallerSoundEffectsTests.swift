import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

@MainActor
struct UninstallerSoundEffectsTests {
    private let zoom = InstalledAppFixtures.app("Zoom", size: 900, leftovers: ["zoom-cache": 50])

    // MARK: Phases

    @Test func anUninstallPlaysOnlyWhenItMovedSomethingToTheTrash() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([zoom.bundle])

        #expect(UninstallerPhase.uninstalling.soundEffect(movingTo: .finished(moved)) == .appUninstalled)
        #expect(UninstallerPhase.uninstalling.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    /// The list loads again after each uninstall: it isn't a scan the user started.
    @Test func loadingTheAppsPlaysNothing() {
        #expect(UninstallerPhase.loading.soundEffect(movingTo: .browsing) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(UninstallerPhase.intro.soundEffect(movingTo: .loading) == nil)
        #expect(UninstallerPhase.browsing.soundEffect(movingTo: .uninstalling) == nil)
        #expect(UninstallerPhase.finished(CleanupReport()).soundEffect(movingTo: .loading) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachUninstallAndNotForTheListLoadedAgain() async {
        let viewModel = UninstallerViewModel(
            scanner: StubAppScanner(events: [.discovered(count: 1), .analyzed(zoom)]),
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        let recorder = SoundEffectRecorder(UninstallerModule(viewModel: viewModel).soundEffects)

        await viewModel.startLoading().value
        viewModel.toggle(zoom)
        viewModel.requestUninstall()
        await viewModel.uninstall()?.value
        await viewModel.done().value

        #expect(recorder.recorded == [.appUninstalled])
    }
}
