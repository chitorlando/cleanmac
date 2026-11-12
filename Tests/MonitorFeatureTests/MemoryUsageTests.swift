import MonitorFeature
import Testing

struct MemoryUsageTests {
    private let pages = MemoryPageCounts(
        pageSize: 16_384,
        free: 1_000,
        wired: 2_000,
        compressed: 3_000,
        internal: 10_000,
        purgeable: 1_000,
        external: 4_000
    )

    @Test func groupsPagesAsActivityMonitorDoes() {
        let usage = MemoryUsage(pages: pages, physical: 1_000_000_000)

        #expect(usage.app == 9_000 * 16_384)
        #expect(usage.wired == 2_000 * 16_384)
        #expect(usage.compressed == 3_000 * 16_384)
        #expect(usage.cachedFiles == 5_000 * 16_384)
        #expect(usage.used == 14_000 * 16_384)
    }

    @Test func leavesTheRestAvailable() {
        let usage = MemoryUsage(physical: 1_000, app: 300, wired: 100, compressed: 100, cachedFiles: 200)

        #expect(usage.available == 500)
        #expect(usage.usedFraction == 0.5)
    }

    @Test func neverReportsMoreThanAllTheMemory() {
        let usage = MemoryUsage(physical: 1_000, app: 900, wired: 200, compressed: 0, cachedFiles: 0)

        #expect(usage.available == 0)
        #expect(usage.usedFraction == 1)
    }

    @Test func countsNoAppMemoryWhenItIsAllPurgeable() {
        let allPurgeable = MemoryPageCounts(pageSize: 4_096, free: 0, wired: 0, compressed: 0, internal: 10, purgeable: 20, external: 0)

        #expect(MemoryUsage(pages: allPurgeable, physical: 1_000_000).app == 0)
    }

    @Test(arguments: [(Int32(1), MemoryPressure.normal), (2, .warning), (4, .critical)])
    func readsThePressureLevel(level: Int32, pressure: MemoryPressure) {
        #expect(MemoryPressure(kernelLevel: level) == pressure)
    }

    @Test func ignoresUnknownPressureLevels() {
        #expect(MemoryPressure(kernelLevel: 3) == nil)
    }

    @Test func readsTheMemoryOfThisMac() throws {
        let reader = HostMemoryStatisticsReader()
        let pages = try #require(reader.pageCounts())

        #expect(reader.physicalMemory > 0)
        #expect(pages.pageSize > 0)
        #expect(MemoryUsage(pages: pages, physical: reader.physicalMemory).used > 0)
        #expect(KernelMemoryPressureReader().pressure() != nil)
    }
}
