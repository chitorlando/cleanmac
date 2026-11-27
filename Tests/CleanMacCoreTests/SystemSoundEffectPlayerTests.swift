@testable import CleanMacCore
import Testing

@MainActor
struct SystemSoundEffectPlayerTests {
    private let library = FakeSoundLibrary()

    private func makePlayer() -> SystemSoundEffectPlayer {
        SystemSoundEffectPlayer { [library] in library.load($0) }
    }

    @Test func playsTheSoundOfTheEffect() {
        let player = makePlayer()

        player.play(.scanFinished)

        #expect(library.loads == [.alert("Tink")])
        #expect(library.sound(.alert("Tink")).starts == 1)
    }

    @Test func loadsEachSoundOnlyTheFirstTime() {
        let player = makePlayer()

        player.play(.cleanupFinished)
        library.sound(.moveToTrash).finish()
        player.play(.appUninstalled)
        library.sound(.moveToTrash).finish()
        player.play(.cleanupFinished)

        #expect(library.loads == [.moveToTrash])
        #expect(library.sound(.moveToTrash).starts == 3)
    }

    /// Two cleanups that end together sound once, not one sound over the other.
    @Test func doesNotStartASoundThatIsStillPlaying() {
        let player = makePlayer()

        player.play(.cleanupFinished)
        player.play(.appUninstalled)

        #expect(library.sound(.moveToTrash).starts == 1)
    }

    @Test func playsAnotherSoundWhileOneIsPlaying() {
        let player = makePlayer()

        player.play(.scanFinished)
        player.play(.threatFound)

        #expect(library.sound(.alert("Tink")).starts == 1)
        #expect(library.sound(.alert("Basso")).starts == 1)
    }

    @Test func playsNothingWhenTheSoundIsNotThere() {
        library.missing = [.alert("Hero")]
        let player = makePlayer()

        player.play(.maintenanceFinished)

        #expect(library.sound(.alert("Hero")).starts == 0)
    }

    @Test func triesAgainASoundThatWasNotThere() {
        library.missing = [.alert("Hero")]
        let player = makePlayer()
        player.play(.maintenanceFinished)

        library.missing = []
        player.play(.maintenanceFinished)

        #expect(library.loads == [.alert("Hero"), .alert("Hero")])
        #expect(library.sound(.alert("Hero")).starts == 1)
    }
}
