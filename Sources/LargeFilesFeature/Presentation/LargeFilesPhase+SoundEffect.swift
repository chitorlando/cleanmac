import CleanMacCore

public extension LargeFilesPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a scan,
    /// whatever it found, also when the user stops it to review what it found so far, or of a
    /// removal that moved files to the Trash. Going back to the list after a removal plays
    /// nothing, nor do the other moves.
    func soundEffect(movingTo next: LargeFilesPhase) -> SoundEffect? {
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
