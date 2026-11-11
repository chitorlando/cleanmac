import MonitorFeature
import Testing

struct CPUUsageTests {
    private let start = CPUTicks(user: 1_000, system: 500, idle: 8_000, nice: 100)

    @Test func splitsTheTimeBetweenReadings() throws {
        let end = CPUTicks(user: 1_300, system: 600, idle: 8_500, nice: 200)

        let usage = try #require(CPUUsage(from: start, to: end))

        #expect(usage.user == 0.4)
        #expect(usage.system == 0.1)
        #expect(usage.total == 0.5)
    }

    @Test func isIdleWhenOnlyIdleTimePassed() throws {
        let end = CPUTicks(user: 1_000, system: 500, idle: 9_000, nice: 100)

        #expect(try #require(CPUUsage(from: start, to: end)).total == 0)
    }

    @Test func needsTimeToPass() {
        #expect(CPUUsage(from: start, to: start) == nil)
    }

    @Test func ignoresCountersThatWentBack() {
        let wrapped = CPUTicks(user: 10, system: 600, idle: 9_000, nice: 100)

        #expect(CPUUsage(from: start, to: wrapped) == nil)
    }

    @Test func addsUpEveryState() {
        #expect(start.total == 9_600)
    }

    @Test func readsTheTicksOfThisMac() throws {
        let ticks = try #require(HostCPUTicksReader().ticks())

        #expect(ticks.total > 0)
    }
}
