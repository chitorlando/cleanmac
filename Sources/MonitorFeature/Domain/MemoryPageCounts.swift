/// Pages of physical memory in each state, as the kernel counts them.
public struct MemoryPageCounts: Equatable, Sendable {
    public let pageSize: UInt64
    public let free: UInt64
    /// Locked in memory by the kernel. It can't be compressed or swapped.
    public let wired: UInt64
    /// Held by the compressor, which keeps other pages in less space.
    public let compressed: UInt64
    /// Anonymous pages: memory that apps allocated, as opposed to cached files.
    public let `internal`: UInt64
    /// Anonymous pages that apps said can be dropped when memory is short.
    public let purgeable: UInt64
    /// Pages that cache files.
    public let external: UInt64

    public init(
        pageSize: UInt64,
        free: UInt64,
        wired: UInt64,
        compressed: UInt64,
        internal: UInt64,
        purgeable: UInt64,
        external: UInt64
    ) {
        self.pageSize = pageSize
        self.free = free
        self.wired = wired
        self.compressed = compressed
        self.internal = `internal`
        self.purgeable = purgeable
        self.external = external
    }
}
