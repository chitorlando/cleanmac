import CleanMacCore
import Foundation
@testable import MonitorFeature
import Testing

@MainActor
struct MenuBarTrashSoundEffectsTests {
    private func makeTrash(_ usages: [TrashUsage], emptier: FakeTrashEmptier = FakeTrashEmptier()) -> MenuBarTrash {
        MenuBarTrash(
            reader: FakeTrashReader(usages),
            service: TrashEmptyingService(emptier: emptier),
            homeBin: MenuBarTrashFixtures.homeBin
        )
    }

    @Test func playsTheSoundOfFinderEachTimeItEmptiesTheTrash() async {
        let trash = makeTrash([MenuBarTrashFixtures.full, MenuBarTrashFixtures.empty, .unreadable, .unreadable])
        let recorder = SoundEffectRecorder(trash.soundEffects)
        await trash.read()

        trash.requestEmpty()
        await trash.empty()
        await trash.read()
        trash.requestEmpty()
        await trash.empty()

        #expect(recorder.recorded == [.trashEmptied, .trashEmptied])
    }

    @Test func playsNothingWhenTheTrashCouldNotBeEmptied() async {
        let trash = makeTrash([MenuBarTrashFixtures.full], emptier: FakeTrashEmptier(error: FakeTrashEmptier.Failure()))
        let recorder = SoundEffectRecorder(trash.soundEffects)
        await trash.read()

        trash.requestEmpty()
        await trash.empty()

        #expect(recorder.recorded.isEmpty)
    }

    /// The menu measures the Trash each time it opens.
    @Test func measuringTheTrashOrAskingToEmptyItPlaysNothing() async {
        let trash = makeTrash([MenuBarTrashFixtures.full, MenuBarTrashFixtures.full])
        let recorder = SoundEffectRecorder(trash.soundEffects)

        await trash.read()
        await trash.read()
        trash.requestEmpty()
        trash.cancelEmpty()

        #expect(recorder.recorded.isEmpty)
    }

    @Test func theMenuPlaysTheSoundsOfItsTrash() async {
        let trash = makeTrash([MenuBarTrashFixtures.full, MenuBarTrashFixtures.empty])
        let menuBar = MenuBarMonitor(
            monitor: MonitorViewModel(sampler: FakeSampler([]), interval: .milliseconds(5), isVisible: { false }),
            preferences: Preferences(storage: InMemoryPreferenceStorage()),
            featureID: "monitor",
            trash: trash
        )
        let recorder = SoundEffectRecorder(menuBar.soundEffects)
        await trash.read()

        trash.requestEmpty()
        await trash.empty()

        #expect(recorder.recorded == [.trashEmptied])
    }
}
