import CleanMacCore
import Testing

@MainActor
struct GatedSoundEffectPlayerTests {
    private let spy = SpySoundEffectPlayer()
    private let userInterfaceSounds = StubUserInterfaceSounds()

    private func makePlayer(preferences: Preferences) -> GatedSoundEffectPlayer {
        GatedSoundEffectPlayer(player: spy, preferences: preferences, userInterfaceSounds: userInterfaceSounds)
    }

    @Test func soundEffectsAreOnUntilTheUserTurnsThemOff() {
        #expect(SoundEffectSettings.isEnabled.key == "soundEffects.isEnabled")
        #expect(SoundEffectSettings.isEnabled.defaultValue)
    }

    @Test func playsWhileTheSettingAndMacOSAllowIt() {
        let player = makePlayer(preferences: Preferences(storage: InMemoryPreferenceStorage()))

        player.play(.scanFinished)
        player.play(.trashEmptied)

        #expect(spy.played == [.scanFinished, .trashEmptied])
    }

    @Test func staysQuietWhenTheUserTurnedTheSoundEffectsOff() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["soundEffects.isEnabled": false]))
        let player = makePlayer(preferences: preferences)

        player.play(.cleanupFinished)

        #expect(spy.played.isEmpty)
    }

    @Test func staysQuietWhileMacOSPlaysNoSoundEffectsOfItsInterface() {
        userInterfaceSounds.set(plays: false)
        let player = makePlayer(preferences: Preferences(storage: InMemoryPreferenceStorage()))

        player.play(.threatFound)

        #expect(spy.played.isEmpty)
    }

    @Test func followsTheSettingAsSoonAsItChanges() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())
        let player = makePlayer(preferences: preferences)

        preferences.set(false, for: SoundEffectSettings.isEnabled)
        player.play(.scanFinished)
        preferences.set(true, for: SoundEffectSettings.isEnabled)
        player.play(.maintenanceFinished)

        #expect(spy.played == [.maintenanceFinished])
    }

    @Test func followsMacOSAsSoonAsItChanges() {
        let player = makePlayer(preferences: Preferences(storage: InMemoryPreferenceStorage()))

        userInterfaceSounds.set(plays: false)
        player.play(.scanFinished)
        userInterfaceSounds.set(plays: true)
        player.play(.appUninstalled)

        #expect(spy.played == [.appUninstalled])
    }
}
