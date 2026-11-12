/// Time every processor of the Mac has spent in each state since it started, in clock ticks.
public struct CPUTicks: Equatable, Sendable {
    public let user: UInt64
    public let system: UInt64
    public let idle: UInt64
    /// Running user code at a lower priority. Counted as user time.
    public let nice: UInt64

    public init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64 = 0) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    public var total: UInt64 { user + system + idle + nice }
}
