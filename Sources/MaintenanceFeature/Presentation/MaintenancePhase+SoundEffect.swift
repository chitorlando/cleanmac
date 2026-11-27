import CleanMacCore

public extension MaintenancePhase {
    /// The sound effect that marks the move from this phase to `next`: the end of a run where
    /// at least one task succeeded. A run where every task failed, such as when the user didn't
    /// give the administrator password, plays nothing, nor do the other moves.
    func soundEffect(movingTo next: MaintenancePhase) -> SoundEffect? {
        guard case .running = self, case .finished(let report) = next,
              report.results.contains(where: { $0.outcome == .succeeded }) else {
            return nil
        }
        return .maintenanceFinished
    }
}
