import Dispatch
import Foundation

/// `SystemSampling` from the processors, memory, volumes and processes of this Mac.
///
/// An actor, so its readings run away from the main thread and keep what the next one
/// compares with: processor ticks and each process's processor time.
public actor SystemSampler: SystemSampling {
    public static let defaultProcessLimit = 5

    /// The parts of the system it reads.
    public struct Readers: Sendable {
        let cpu: any CPUTicksReading
        let memory: any MemoryStatisticsReading
        let memoryPressure: any MemoryPressureReading
        let volumes: any VolumeCapacityReading
        let processes: any ProcessListing
        let identities: any ProcessIdentityResolving

        public init(
            cpu: any CPUTicksReading,
            memory: any MemoryStatisticsReading,
            memoryPressure: any MemoryPressureReading,
            volumes: any VolumeCapacityReading,
            processes: any ProcessListing,
            identities: any ProcessIdentityResolving
        ) {
            self.cpu = cpu
            self.memory = memory
            self.memoryPressure = memoryPressure
            self.volumes = volumes
            self.processes = processes
            self.identities = identities
        }
    }

    private let readers: Readers
    private let volumeURLs: [URL]
    private let processLimit: Int
    private let now: @Sendable () -> UInt64
    private var previousTicks: CPUTicks?
    private var previousProcessTimes: [Int32: UInt64] = [:]
    private var previousTime: UInt64?

    /// - Parameters:
    ///   - volumeURLs: Items whose volumes are shown, each volume once.
    ///   - now: Current time in nanoseconds, from a clock that never goes back.
    public init(
        readers: Readers,
        volumeURLs: [URL],
        processLimit: Int = defaultProcessLimit,
        now: @escaping @Sendable () -> UInt64 = { DispatchTime.now().uptimeNanoseconds }
    ) {
        self.readers = readers
        self.volumeURLs = volumeURLs
        self.processLimit = processLimit
        self.now = now
    }

    public func sample() -> SystemSnapshot {
        let time = now()
        let ticks = readers.cpu.ticks()
        let cpu = previousTicks.flatMap { previous in ticks.flatMap { CPUUsage(from: previous, to: $0) } }
        previousTicks = ticks

        let (topByCPU, topByMemory) = topProcesses(at: time)
        previousTime = time

        return SystemSnapshot(
            cpu: cpu,
            memory: readers.memory.pageCounts().map { MemoryUsage(pages: $0, physical: readers.memory.physicalMemory) },
            memoryPressure: readers.memoryPressure.pressure(),
            volumes: readers.volumes.capacities(ofVolumesHolding: volumeURLs),
            topByCPU: topByCPU,
            topByMemory: topByMemory
        )
    }

    private func topProcesses(at time: UInt64) -> ([ProcessUsage], [ProcessUsage]) {
        let samples = readers.processes.processes()
        let elapsed = previousTime.map { time > $0 ? time - $0 : 0 } ?? 0
        let usages = ProcessUsageCalculator.usages(of: samples, since: previousProcessTimes, elapsedNanoseconds: elapsed)
        previousProcessTimes = ProcessUsageCalculator.cpuTimes(of: samples)

        let topByCPU = elapsed > 0 ? ProcessRanking.cpu.top(usages, limit: processLimit) : []
        let topByMemory = ProcessRanking.memory.top(usages, limit: processLimit)
        return (topByCPU.map(identified), topByMemory.map(identified))
    }

    private func identified(_ usage: ProcessUsage) -> ProcessUsage {
        readers.identities.identity(of: usage.pid).map(usage.identified(as:)) ?? usage
    }
}

public extension SystemSampler {
    /// Sampler of this Mac, showing the startup volume and the home folder's volume.
    static func live() -> SystemSampler {
        SystemSampler(
            readers: Readers(
                cpu: HostCPUTicksReader(),
                memory: HostMemoryStatisticsReader(),
                memoryPressure: KernelMemoryPressureReader(),
                volumes: LocalVolumeCapacityReader(),
                processes: UserProcessLister(),
                identities: RunningProcessIdentityResolver()
            ),
            volumeURLs: [URL(filePath: "/"), FileManager.default.homeDirectoryForCurrentUser]
        )
    }
}
