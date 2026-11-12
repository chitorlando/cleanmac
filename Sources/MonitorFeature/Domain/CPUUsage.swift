/// Share of the processors' time spent working between two readings, from 0 to 1.
public struct CPUUsage: Equatable, Sendable {
    /// Running apps and other user code.
    public let user: Double
    /// Running the kernel on their behalf.
    public let system: Double

    public init(user: Double, system: Double) {
        self.user = user
        self.system = system
    }

    public var total: Double { user + system }

    /// Usage between two readings, or `nil` when no time passed or the counters went back,
    /// as they do when they wrap around.
    public init?(from previous: CPUTicks, to current: CPUTicks) {
        guard
            current.user >= previous.user, current.system >= previous.system,
            current.idle >= previous.idle, current.nice >= previous.nice,
            current.total > previous.total
        else { return nil }
        let elapsed = Double(current.total - previous.total)
        let user = Double(current.user - previous.user + current.nice - previous.nice)
        self.init(user: user / elapsed, system: Double(current.system - previous.system) / elapsed)
    }
}
