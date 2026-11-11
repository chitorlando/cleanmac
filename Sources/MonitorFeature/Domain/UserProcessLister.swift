import Darwin

/// `ProcessListing` from the kernel's process table, limited to the current user's processes,
/// the only ones it can read without special rights.
public struct UserProcessLister: ProcessListing {
    /// Processor time comes in Mach time units, which are nanoseconds only on some Macs.
    private let nanosecondsPerUnit: Double

    public init() {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        nanosecondsPerUnit = timebase.denom > 0 ? Double(timebase.numer) / Double(timebase.denom) : 1
    }

    public func processes() -> [ProcessSample] {
        processIDs().compactMap(sample)
    }

    private func processIDs() -> [pid_t] {
        let uid = UInt32(getuid())
        let bytes = proc_listpids(UInt32(PROC_UID_ONLY), uid, nil, 0)
        guard bytes > 0 else { return [] }
        // Room for processes started between the two calls.
        var pids = [pid_t](repeating: 0, count: Int(bytes) / MemoryLayout<pid_t>.stride + 32)
        let filled = pids.withUnsafeMutableBytes { buffer in
            proc_listpids(UInt32(PROC_UID_ONLY), uid, buffer.baseAddress, Int32(buffer.count))
        }
        guard filled > 0 else { return [] }
        return pids.prefix(Int(filled) / MemoryLayout<pid_t>.stride).filter { $0 > 0 }
    }

    private func sample(of pid: pid_t) -> ProcessSample? {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else { return nil }
        let units = Double(info.pti_total_user) + Double(info.pti_total_system)
        return ProcessSample(
            pid: pid,
            name: name(of: pid),
            cpuNanoseconds: UInt64(units * nanosecondsPerUnit),
            residentBytes: info.pti_resident_size
        )
    }

    private func name(of pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        guard proc_name(pid, &buffer, UInt32(buffer.count)) > 0 else { return String(pid) }
        return String(nullTerminated: buffer)
    }
}
