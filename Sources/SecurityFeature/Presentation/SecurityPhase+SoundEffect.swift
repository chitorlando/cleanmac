import CleanMacCore

public extension SecurityPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a review,
    /// whatever it found. Stopping a review or leaving its results plays nothing.
    func soundEffect(movingTo next: SecurityPhase) -> SoundEffect? {
        guard case .reviewing = self, case .results = next else { return nil }
        return .scanFinished
    }
}
