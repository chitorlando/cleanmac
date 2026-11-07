import CleanMacCore

/// Steps the system junk screen goes through.
public enum SystemJunkPhase: Equatable, Sendable {
    case idle
    case scanning
    case review
    case cleaning
    case finished(CleanupReport)
}
