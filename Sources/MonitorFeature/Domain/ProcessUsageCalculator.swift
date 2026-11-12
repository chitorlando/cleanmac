/// Turns two readings of the process table into what each process used in between.
public enum ProcessUsageCalculator {
    /// - Parameters:
    ///   - previous: Processor time of each process at the previous reading, by pid.
    ///   - elapsedNanoseconds: Time between the two readings.
    /// - Returns: One usage per sample. Processes that weren't in the previous reading, or
    ///   whose time went back because the pid was reused, count as using no processor yet.
    public static func usages(
        of samples: [ProcessSample],
        since previous: [Int32: UInt64],
        elapsedNanoseconds: UInt64
    ) -> [ProcessUsage] {
        samples.map { sample in
            var cpu = 0.0
            if elapsedNanoseconds > 0, let before = previous[sample.pid], sample.cpuNanoseconds >= before {
                cpu = Double(sample.cpuNanoseconds - before) / Double(elapsedNanoseconds)
            }
            return ProcessUsage(pid: sample.pid, name: sample.name, cpu: cpu, memoryBytes: sample.residentBytes)
        }
    }

    /// Processor time of each sample by pid, to pass as `previous` next time.
    public static func cpuTimes(of samples: [ProcessSample]) -> [Int32: UInt64] {
        Dictionary(samples.map { ($0.pid, $0.cpuNanoseconds) }, uniquingKeysWith: { _, last in last })
    }
}
