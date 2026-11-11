import Darwin
import Foundation

/// `MemoryStatisticsReading` from the kernel's virtual memory statistics.
public struct HostMemoryStatisticsReader: MemoryStatisticsReading {
    public init() {}

    public var physicalMemory: UInt64 { ProcessInfo.processInfo.physicalMemory }

    public func pageCounts() -> MemoryPageCounts? {
        var statistics = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        var pageSize: vm_size_t = 0
        guard result == KERN_SUCCESS, host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return nil }

        return MemoryPageCounts(
            pageSize: UInt64(pageSize),
            free: UInt64(statistics.free_count),
            wired: UInt64(statistics.wire_count),
            compressed: UInt64(statistics.compressor_page_count),
            internal: UInt64(statistics.internal_page_count),
            purgeable: UInt64(statistics.purgeable_count),
            external: UInt64(statistics.external_page_count)
        )
    }
}
