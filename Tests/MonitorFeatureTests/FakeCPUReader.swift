import MonitorFeature

struct FakeCPUReader: CPUTicksReading {
    let readings: ReadingQueue<CPUTicks>
    func ticks() -> CPUTicks? { readings.next() }
}
