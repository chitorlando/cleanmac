/// Reads how long the processors have spent in each state.
public protocol CPUTicksReading: Sendable {
    /// Ticks added up over every processor, or `nil` when they can't be read.
    func ticks() -> CPUTicks?
}
