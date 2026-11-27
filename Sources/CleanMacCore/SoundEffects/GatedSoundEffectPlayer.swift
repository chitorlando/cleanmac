/// `SoundEffectPlaying` that plays through another player only while the sound effects may be
/// heard: the user didn't turn them off in the settings of the app, and macOS plays the sound
/// effects of its own interface.
///
/// Both are checked each time an effect would play, so a change in either applies at once.
@MainActor
public struct GatedSoundEffectPlayer: SoundEffectPlaying {
    private let player: any SoundEffectPlaying
    private let preferences: Preferences
    private let userInterfaceSounds: any UserInterfaceSoundsReading

    /// - Parameters:
    ///   - player: Plays the effects that may be heard.
    ///   - preferences: Where the user chooses whether the app plays sound effects (see
    ///     `SoundEffectSettings.isEnabled`).
    ///   - userInterfaceSounds: Tells whether macOS plays the sound effects of its interface.
    public init(
        player: any SoundEffectPlaying,
        preferences: Preferences,
        userInterfaceSounds: any UserInterfaceSoundsReading
    ) {
        self.player = player
        self.preferences = preferences
        self.userInterfaceSounds = userInterfaceSounds
    }

    public func play(_ effect: SoundEffect) {
        guard mayPlay else { return }
        player.play(effect)
    }

    /// Whether sound effects may be heard now. The setting of the app is read first, since
    /// it's the cheaper of the two.
    var mayPlay: Bool {
        preferences.value(of: SoundEffectSettings.isEnabled) && userInterfaceSounds.playsUserInterfaceSounds
    }
}
