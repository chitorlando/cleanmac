import Foundation
@testable import MonitorFeature
import Testing

struct MenuBarReadoutTests {
    private let startup = VolumeCapacity(url: URL(filePath: "/"), name: "Macintosh HD", totalBytes: 1_000, availableBytes: 250)
    private let data = VolumeCapacity(url: URL(filePath: "/System/Volumes/Data"), name: "Data", totalBytes: 1_000, availableBytes: 250)

    private func process(_ pid: Int32, cpu: Double) -> ProcessUsage {
        ProcessUsage(pid: pid, name: "Process \(pid)", cpu: cpu, memoryBytes: 100)
    }

    @Test func showsTheReadingsOfTheMonitorsScreen() {
        let cpu = CPUUsage(user: 0.2, system: 0.1)
        let memory = MemoryUsage(physical: 16, app: 4, wired: 2, compressed: 1, cachedFiles: 3)

        let readout = MenuBarReadout(SystemSnapshot(cpu: cpu, memory: memory, memoryPressure: .warning))

        #expect(readout.cpu == cpu)
        #expect(readout.memory == memory)
        #expect(readout.memoryPressure == .warning)
    }

    @Test func showsNothingBeforeTheFirstReading() {
        let readout = MenuBarReadout(SystemSnapshot())

        #expect(readout.cpu == nil)
        #expect(readout.memory == nil)
        #expect(readout.memoryPressure == nil)
        #expect(readout.startupVolume == nil)
        #expect(readout.busiestProcesses.isEmpty)
    }

    @Test func showsTheStartupDiskWhereverTheMonitorListsIt() {
        let readout = MenuBarReadout(SystemSnapshot(volumes: [data, startup]))

        #expect(readout.startupVolume == startup)
    }

    @Test func showsTheFirstVolumeWhenTheStartupDiskCouldNotBeRead() {
        let readout = MenuBarReadout(SystemSnapshot(volumes: [data]))

        #expect(readout.startupVolume == data)
    }

    @Test func listsOnlyTheThreeBusiestProcessesByProcessorUse() {
        let byCPU = [process(1, cpu: 0.9), process(2, cpu: 0.5), process(3, cpu: 0.3), process(4, cpu: 0.2), process(5, cpu: 0.1)]

        let readout = MenuBarReadout(SystemSnapshot(topByCPU: byCPU, topByMemory: byCPU.reversed()))

        #expect(readout.busiestProcesses.map(\.pid) == [1, 2, 3])
    }
}
