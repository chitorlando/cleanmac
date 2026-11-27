import CleanMacCore
import LoginItemsFeature
import Testing

@MainActor
struct LoginItemsSoundEffectsTests {
    private let mine = loginItem("com.example.mine", owner: "Mine")

    // MARK: Phases

    @Test func aRemovalPlaysOnlyWhenItMovedAgentsToTheTrash() async {
        let moved = await CleanupService(remover: RecordingRemover()).clean([mine.item])

        #expect(LoginItemsPhase.removing.soundEffect(movingTo: .finished(moved)) == .cleanupFinished)
        #expect(LoginItemsPhase.removing.soundEffect(movingTo: .finished(CleanupReport())) == nil)
    }

    /// The items are read again after each removal: it isn't a scan the user started.
    @Test func readingTheItemsPlaysNothing() {
        #expect(LoginItemsPhase.loading.soundEffect(movingTo: .browsing) == nil)
    }

    @Test func otherMovesPlayNothing() {
        #expect(LoginItemsPhase.intro.soundEffect(movingTo: .loading) == nil)
        #expect(LoginItemsPhase.browsing.soundEffect(movingTo: .removing) == nil)
        #expect(LoginItemsPhase.finished(CleanupReport()).soundEffect(movingTo: .loading) == nil)
    }

    // MARK: Module

    @Test func playsOnceForEachRemovalAndNotForTheItemsReadAgain() async {
        let viewModel = LoginItemsViewModel(
            scanner: StubLoginItemScanner(items: [mine]),
            cleanupService: CleanupService(remover: RecordingRemover()),
            settingsOpener: SpySettingsOpener()
        )
        let recorder = SoundEffectRecorder(LoginItemsModule(viewModel: viewModel).soundEffects)

        await viewModel.startLoading().value
        viewModel.toggle(mine)
        viewModel.requestRemoval()
        await viewModel.remove()?.value
        await viewModel.done().value

        #expect(recorder.recorded == [.cleanupFinished])
    }
}
