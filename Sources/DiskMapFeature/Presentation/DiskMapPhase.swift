import CleanMacCore

/// Steps the disk map screen goes through.
public enum DiskMapPhase: Equatable, Sendable {
    case intro
    case scanning
    case map
    case removing
    case finished(CleanupReport)
}
