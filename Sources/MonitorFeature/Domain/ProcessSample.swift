/// One of the user's processes, as read at a moment.
public struct ProcessSample: Equatable, Sendable {
    public let pid: Int32
    /// Short name of the executable, as the kernel keeps it.
    public let name: String
    /// Processor time used since it started, user and system together, in nanoseconds.
    public let cpuNanoseconds: UInt64
    /// Physical memory it holds, in bytes.
    public let residentBytes: UInt64

    public init(pid: Int32, name: String, cpuNanoseconds: UInt64, residentBytes: UInt64) {
        self.pid = pid
        self.name = name
        self.cpuNanoseconds = cpuNanoseconds
        self.residentBytes = residentBytes
    }
}
