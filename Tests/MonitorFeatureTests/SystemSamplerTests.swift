import Foundation
import MonitorFeature
import Testing

struct SystemSamplerTests {
    private let disk = VolumeCapacity(url: URL(filePath: "/"), name: "Macintosh HD", totalBytes: 1_000, availableBytes: 400)
    private let pages = MemoryPageCounts(pageSize: 1_000, free: 100, wired: 100, compressed: 50, internal: 300, purgeable: 0, external: 200)

    private func sampler(
        ticks: [CPUTicks] = [CPUTicks(user: 0, system: 0, idle: 0), CPUTicks(user: 30, system: 10, idle: 60)],
        processes: [[ProcessSample]] = [],
        identities: [Int32: ProcessIdentity] = [:],
        times: [UInt64] = [0, 2_000_000_000]
    ) -> SystemSampler {
        let clock = ReadingQueue(times)
        return SystemSampler(
            readers: .init(
                cpu: FakeCPUReader(readings: ReadingQueue(ticks)),
                memory: FakeMemoryReader(physicalMemory: 1_000_000, pages: pages),
                memoryPressure: FakePressureReader(level: .warning),
                volumes: FakeVolumeReader(volumes: ["/": disk]),
                processes: FakeProcessLister(readings: ReadingQueue(processes)),
                identities: FakeIdentityResolver(identities: identities)
            ),
            volumeURLs: [URL(filePath: "/"), URL(filePath: "/Users/test")],
            processLimit: 2,
            now: { clock.next() ?? 0 }
        )
    }

    private func process(_ pid: Int32, _ name: String, seconds: Double, memory: UInt64) -> ProcessSample {
        ProcessSample(pid: pid, name: name, cpuNanoseconds: UInt64(seconds * 1_000_000_000), residentBytes: memory)
    }

    @Test func comparesEachReadingWithThePreviousOne() async {
        let sampler = sampler()

        let first = await sampler.sample()
        let second = await sampler.sample()

        #expect(first.cpu == nil)
        #expect(second.cpu == CPUUsage(user: 0.3, system: 0.1))
    }

    @Test func readsMemoryPressureAndVolumes() async {
        let snapshot = await sampler().sample()

        #expect(snapshot.memory == MemoryUsage(pages: pages, physical: 1_000_000))
        #expect(snapshot.memoryPressure == .warning)
        #expect(snapshot.volumes == [disk])
    }

    @Test func ranksProcessesOnceThereIsSomethingToCompare() async {
        let sampler = sampler(processes: [
            [process(1, "Safari", seconds: 1, memory: 500), process(2, "Xcode", seconds: 1, memory: 900), process(3, "Mail", seconds: 1, memory: 100)],
            [process(1, "Safari", seconds: 2, memory: 500), process(2, "Xcode", seconds: 1.5, memory: 900), process(3, "Mail", seconds: 1, memory: 100)]
        ])

        let first = await sampler.sample()
        let second = await sampler.sample()

        #expect(first.topByCPU.isEmpty)
        #expect(first.topByMemory.map(\.name) == ["Xcode", "Safari"])
        #expect(second.topByCPU.map(\.name) == ["Safari", "Xcode"])
        #expect(second.topByCPU.map(\.cpu) == [0.5, 0.25])
    }

    @Test func showsProcessesUnderTheirAppsName() async {
        let app = URL(filePath: "/Applications/Safari.app")
        let sampler = sampler(
            processes: [[process(1, "com.apple.WebKit", seconds: 1, memory: 500)]],
            identities: [1: ProcessIdentity(name: "Safari", iconURL: app)]
        )

        let snapshot = await sampler.sample()

        #expect(snapshot.topByMemory.first?.name == "Safari")
        #expect(snapshot.topByMemory.first?.iconURL == app)
    }
}
