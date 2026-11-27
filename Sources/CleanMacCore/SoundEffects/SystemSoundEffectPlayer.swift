import AppKit

/// `SoundEffectPlaying` with the sounds that come with macOS: each effect plays its
/// `systemSound`, from where macOS keeps it.
///
/// A sound is loaded the first time it plays and kept for the next times. One that is still
/// playing isn't started again over itself, so moments close together sound once. It plays
/// every effect it's given: whether one should be heard is up to `GatedSoundEffectPlayer`.
@MainActor
public final class SystemSoundEffectPlayer: SoundEffectPlaying {
    private let load: @MainActor (SystemSound) -> (any PlayableSound)?
    private var loaded: [SystemSound: any PlayableSound] = [:]

    public convenience init() {
        self.init { NSSound.system($0) }
    }

    /// - Parameter load: The sound a `SystemSound` stands for, or `nil` when it isn't there.
    init(load: @escaping @MainActor (SystemSound) -> (any PlayableSound)?) {
        self.load = load
    }

    public func play(_ effect: SoundEffect) {
        guard let sound = sound(for: effect.systemSound), !sound.isPlaying else { return }
        sound.play()
    }

    /// The sound `systemSound` stands for, loaded the first time. One that couldn't be loaded
    /// is tried again the next time.
    private func sound(for systemSound: SystemSound) -> (any PlayableSound)? {
        if let sound = loaded[systemSound] {
            return sound
        }
        let sound = load(systemSound)
        loaded[systemSound] = sound
        return sound
    }
}
