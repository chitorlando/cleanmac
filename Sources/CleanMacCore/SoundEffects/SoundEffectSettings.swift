/// What the user can choose about the sound effects of the app.
public enum SoundEffectSettings {
    /// Whether the app plays a short sound at its key moments, such as when a scan ends. macOS
    /// keeps them quiet anyway while it plays no sound effects of its own interface.
    public static let isEnabled = Setting(key: "soundEffects.isEnabled", defaultValue: true)
}
