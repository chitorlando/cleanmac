@testable import CleanMacApp
import CleanMacCore
import CleanMacUI
import Combine
import Testing

@MainActor
struct AppCompositionSoundEffectsTests {
    private let spy = SpySoundEffectPlayer()

    /// Whichever feature is on screen, or the menu bar.
    @Test func playsTheSoundEffectsOfEveryFeatureAsTheyHappen() {
        let systemJunk = PassthroughSubject<SoundEffect, Never>()
        let menuBar = PassthroughSubject<SoundEffect, Never>()
        let playback = AppComposition.playSoundEffects(
            [systemJunk.eraseToAnyPublisher(), menuBar.eraseToAnyPublisher()],
            through: spy
        )

        systemJunk.send(.scanFinished)
        menuBar.send(.trashEmptied)
        systemJunk.send(.cleanupFinished)

        #expect(spy.played == [.scanFinished, .trashEmptied, .cleanupFinished])
        playback.cancel()
    }

    @Test func stopsPlayingOnceCancelled() {
        let maintenance = PassthroughSubject<SoundEffect, Never>()
        let playback = AppComposition.playSoundEffects([maintenance.eraseToAnyPublisher()], through: spy)

        playback.cancel()
        maintenance.send(.maintenanceFinished)

        #expect(spy.played.isEmpty)
    }

    /// A feature with no sound effects of its own, which keeps the default, doesn't stop the
    /// others.
    @Test func featuresWithoutSoundEffectsSendNone() {
        let feature = FakeFeature("feature", in: .files)
        let malware = PassthroughSubject<SoundEffect, Never>()
        let playback = AppComposition.playSoundEffects(
            [feature.soundEffects, malware.eraseToAnyPublisher()],
            through: spy
        )

        malware.send(.threatFound)

        #expect(spy.played == [.threatFound])
        playback.cancel()
    }
}
