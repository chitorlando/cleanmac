import Darwin

/// `MemoryPressureReading` from the level the kernel publishes, a single cheap read.
public struct KernelMemoryPressureReader: MemoryPressureReading {
    public init() {}

    public func pressure() -> MemoryPressure? {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else { return nil }
        return MemoryPressure(kernelLevel: level)
    }
}
