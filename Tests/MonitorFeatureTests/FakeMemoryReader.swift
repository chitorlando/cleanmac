import MonitorFeature

struct FakeMemoryReader: MemoryStatisticsReading {
    var physicalMemory: UInt64 = 1_000_000
    var pages: MemoryPageCounts?
    func pageCounts() -> MemoryPageCounts? { pages }
}
