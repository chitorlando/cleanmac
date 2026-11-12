/// Takes readings of the system for the monitor. Each reading compares with the previous one.
public protocol SystemSampling: Sendable {
    func sample() async -> SystemSnapshot
}
