/// A sound loaded and ready to play, such as an `NSSound`.
@MainActor
protocol PlayableSound: AnyObject {
    /// Whether the sound is playing now.
    var isPlaying: Bool { get }

    /// Starts the sound, which goes on playing by itself. Returns whether it started.
    @discardableResult
    func play() -> Bool
}
