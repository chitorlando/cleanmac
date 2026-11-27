import CleanMacCore

/// Plays nothing: records each sound effect it's asked to play, in order.
@MainActor
final class SpySoundEffectPlayer: SoundEffectPlaying {
    private(set) var played: [SoundEffect] = []

    func play(_ effect: SoundEffect) {
        played.append(effect)
    }
}
