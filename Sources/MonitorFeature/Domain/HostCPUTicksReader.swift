import Darwin

/// `CPUTicksReading` from the kernel's per-processor load counters.
public struct HostCPUTicksReader: CPUTicksReading {
    public init() {}

    public func ticks() -> CPUTicks? {
        var processorCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &processorCount, &info, &infoCount)
        guard result == KERN_SUCCESS, let info else { return nil }
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        var user: UInt64 = 0, system: UInt64 = 0, idle: UInt64 = 0, nice: UInt64 = 0
        for processor in 0..<Int(processorCount) {
            let base = processor * Int(CPU_STATE_MAX)
            user += Self.ticks(info[base + Int(CPU_STATE_USER)])
            system += Self.ticks(info[base + Int(CPU_STATE_SYSTEM)])
            idle += Self.ticks(info[base + Int(CPU_STATE_IDLE)])
            nice += Self.ticks(info[base + Int(CPU_STATE_NICE)])
        }
        return CPUTicks(user: user, system: system, idle: idle, nice: nice)
    }

    /// The counters are unsigned 32-bit values stored in signed integers.
    private static func ticks(_ value: integer_t) -> UInt64 {
        UInt64(UInt32(bitPattern: value))
    }
}
