/// Takes readings of the system for the monitor. Each reading compares with the previous one.
public protocol SystemSampling: Sendable {
    func sample() async -> SystemSnapshot
    /// Forgets the previous reading, so the next one has nothing to compare with, as the
    /// first one does. For after a pause, whose average the next reading would show otherwise.
    func forgetPreviousReading() async
}
