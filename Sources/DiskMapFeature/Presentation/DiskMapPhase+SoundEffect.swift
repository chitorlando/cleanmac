import CleanMacCore

public extension DiskMapPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a scan, when
    /// the map shows, or of a removal that moved items to the Trash. Stopping a scan, which
    /// shows no map, and going back to the map after a removal play nothing.
    func soundEffect(movingTo next: DiskMapPhase) -> SoundEffect? {
        switch (self, next) {
        case (.scanning, .map):
            return .scanFinished
        case (.removing, .finished(let report)):
            return report.soundEffect
        default:
            return nil
        }
    }
}
