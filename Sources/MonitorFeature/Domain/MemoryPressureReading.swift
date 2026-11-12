/// Reads the memory pressure macOS reports.
public protocol MemoryPressureReading: Sendable {
    func pressure() -> MemoryPressure?
}
