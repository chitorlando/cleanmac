import Foundation

/// What a process used since the previous reading.
public struct ProcessUsage: Identifiable, Equatable, Sendable {
    public let pid: Int32
    public let name: String
    /// The app bundle or executable whose icon stands for the process, when known.
    public let iconURL: URL?
    /// Processor time used, where 1 is one processor kept fully busy, as in Activity Monitor.
    public let cpu: Double
    public let memoryBytes: UInt64

    public init(pid: Int32, name: String, iconURL: URL? = nil, cpu: Double, memoryBytes: UInt64) {
        self.pid = pid
        self.name = name
        self.iconURL = iconURL
        self.cpu = cpu
        self.memoryBytes = memoryBytes
    }

    public var id: Int32 { pid }

    /// The same usage shown as `identity` says.
    public func identified(as identity: ProcessIdentity) -> ProcessUsage {
        ProcessUsage(pid: pid, name: identity.name ?? name, iconURL: identity.iconURL, cpu: cpu, memoryBytes: memoryBytes)
    }
}
