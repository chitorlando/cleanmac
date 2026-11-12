/// Everything the monitor shows at a moment.
public struct SystemSnapshot: Equatable, Sendable {
    /// `nil` on the first reading, which has nothing to compare with.
    public let cpu: CPUUsage?
    public let memory: MemoryUsage?
    public let memoryPressure: MemoryPressure?
    public let volumes: [VolumeCapacity]
    /// Empty on the first reading, which has nothing to compare with.
    public let topByCPU: [ProcessUsage]
    public let topByMemory: [ProcessUsage]

    public init(
        cpu: CPUUsage? = nil,
        memory: MemoryUsage? = nil,
        memoryPressure: MemoryPressure? = nil,
        volumes: [VolumeCapacity] = [],
        topByCPU: [ProcessUsage] = [],
        topByMemory: [ProcessUsage] = []
    ) {
        self.cpu = cpu
        self.memory = memory
        self.memoryPressure = memoryPressure
        self.volumes = volumes
        self.topByCPU = topByCPU
        self.topByMemory = topByMemory
    }
}
