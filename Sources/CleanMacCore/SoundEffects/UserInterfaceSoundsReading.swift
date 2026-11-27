/// Tells whether macOS plays the sound effects of its interface, as the user chose with “Play
/// user interface sound effects” in the Sound settings.
public protocol UserInterfaceSoundsReading: Sendable {
    /// Whether macOS plays the sound effects of its interface now.
    var playsUserInterfaceSounds: Bool { get }
}
