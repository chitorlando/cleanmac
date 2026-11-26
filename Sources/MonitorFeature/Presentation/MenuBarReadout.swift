import Foundation

/// What the menu of the menu bar monitor shows of a reading: a summary of each section of the
/// monitor's screen.
struct MenuBarReadout: Equatable {
    /// The menu lists fewer processes than the monitor's screen, to stay small.
    static let processLimit = 3

    let cpu: CPUUsage?
    let memory: MemoryUsage?
    let memoryPressure: MemoryPressure?
    /// The startup disk, or the first volume read when it isn't among them.
    let startupVolume: VolumeCapacity?
    /// The processes that use the processors most, the busiest first. Empty until the second
    /// reading, which has one to compare with.
    let busiestProcesses: [ProcessUsage]

    init(_ snapshot: SystemSnapshot) {
        cpu = snapshot.cpu
        memory = snapshot.memory
        memoryPressure = snapshot.memoryPressure
        startupVolume = snapshot.volumes.first { $0.url.path == "/" } ?? snapshot.volumes.first
        busiestProcesses = Array(snapshot.topByCPU.prefix(Self.processLimit))
    }
}
