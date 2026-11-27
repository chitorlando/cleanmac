import CleanMacCore

public extension DuplicatesPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a scan,
    /// whatever it found, also when the user stops it to review the groups found so far, or of a
    /// removal that moved copies to the Trash. Going back to the list after a removal plays
    /// nothing, nor do the other moves.
    func soundEffect(movingTo next: DuplicatesPhase) -> SoundEffect? {
        switch (self, next) {
        case (.scanning, .review):
            return .scanFinished
        case (.removing, .finished(let report)):
            return report.soundEffect
        default:
            return nil
        }
    }
}
