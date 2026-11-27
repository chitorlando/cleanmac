import CleanMacCore

public extension PrivacyPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a scan,
    /// whatever it found, or of a cleanup that moved caches to the Trash. Other moves, such as
    /// stopping a scan or leaving a report, play nothing.
    func soundEffect(movingTo next: PrivacyPhase) -> SoundEffect? {
        switch (self, next) {
        case (.scanning, .review):
            return .scanFinished
        case (.cleaning, .finished(let report)):
            return report.soundEffect
        default:
            return nil
        }
    }
}
