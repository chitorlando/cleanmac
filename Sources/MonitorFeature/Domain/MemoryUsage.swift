/// How the physical memory is used, in bytes, grouped as Activity Monitor does.
public struct MemoryUsage: Equatable, Sendable {
    public let physical: UInt64
    /// Memory that apps allocated and can't drop.
    public let app: UInt64
    public let wired: UInt64
    public let compressed: UInt64
    /// Files kept in memory to open them faster, freed as soon as apps need the space.
    public let cachedFiles: UInt64

    public init(physical: UInt64, app: UInt64, wired: UInt64, compressed: UInt64, cachedFiles: UInt64) {
        self.physical = physical
        self.app = app
        self.wired = wired
        self.compressed = compressed
        self.cachedFiles = cachedFiles
    }

    public init(pages: MemoryPageCounts, physical: UInt64) {
        let appPages = pages.internal > pages.purgeable ? pages.internal - pages.purgeable : 0
        self.init(
            physical: physical,
            app: appPages * pages.pageSize,
            wired: pages.wired * pages.pageSize,
            compressed: pages.compressed * pages.pageSize,
            cachedFiles: (pages.external + pages.purgeable) * pages.pageSize
        )
    }

    /// Memory in use: app memory, wired and compressed.
    public var used: UInt64 { app + wired + compressed }

    /// Memory apps can still get, cached files included, since they make way.
    public var available: UInt64 { physical > used ? physical - used : 0 }

    /// Share of the physical memory in use, from 0 to 1.
    public var usedFraction: Double {
        physical > 0 ? min(Double(used) / Double(physical), 1) : 0
    }
}
