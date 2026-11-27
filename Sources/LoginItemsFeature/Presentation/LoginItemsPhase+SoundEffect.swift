import CleanMacCore

public extension LoginItemsPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a removal
    /// that moved agents to the Trash. Reading the login items plays nothing, since they're read
    /// again after each removal, nor do the other moves.
    func soundEffect(movingTo next: LoginItemsPhase) -> SoundEffect? {
        guard case .removing = self, case .finished(let report) = next else { return nil }
        return report.soundEffect
    }
}
