/// How hard macOS is working to find memory for the apps.
public enum MemoryPressure: Equatable, Sendable {
    /// There's enough memory.
    case normal
    /// macOS is compressing memory and dropping caches.
    case warning
    /// Memory is short and apps may slow down.
    case critical

    /// The kernel's level: 1 for normal, 2 for warning and 4 for critical.
    public init?(kernelLevel: Int32) {
        switch kernelLevel {
        case 1: self = .normal
        case 2: self = .warning
        case 4: self = .critical
        default: return nil
        }
    }
}
