import MonitorFeature

struct FakePressureReader: MemoryPressureReading {
    var level: MemoryPressure?
    func pressure() -> MemoryPressure? { level }
}
