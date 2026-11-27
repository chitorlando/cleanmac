/// Plays the sound effects of the app.
public protocol SoundEffectPlaying: Sendable {
    /// Plays the sound of `effect`, or nothing when it shouldn't be heard.
    @MainActor func play(_ effect: SoundEffect)
}
