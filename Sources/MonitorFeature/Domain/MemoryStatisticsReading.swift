/// Reads how the physical memory is used.
public protocol MemoryStatisticsReading: Sendable {
    /// Installed memory, in bytes.
    var physicalMemory: UInt64 { get }

    /// Pages in each state, or `nil` when they can't be read.
    func pageCounts() -> MemoryPageCounts?
}
