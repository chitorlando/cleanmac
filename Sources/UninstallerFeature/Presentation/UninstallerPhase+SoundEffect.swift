import CleanMacCore

public extension UninstallerPhase {
    /// The sound effect that marks the move from this phase to `next`: the end of an uninstall
    /// that moved apps, or what they left behind, to the Trash. Loading the list of apps plays
    /// nothing, since it loads again after each uninstall, nor do the other moves.
    func soundEffect(movingTo next: UninstallerPhase) -> SoundEffect? {
        guard case .uninstalling = self, case .finished(let report) = next, report.removedCount > 0 else {
            return nil
        }
        return .appUninstalled
    }
}
