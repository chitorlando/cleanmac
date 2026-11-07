import CleanMacCore

/// Steps the duplicates screen goes through.
public enum DuplicatesPhase: Equatable, Sendable {
    case intro
    case scanning
    case review
    case removing
    case finished(CleanupReport)
}
