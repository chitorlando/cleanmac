import CleanMacCore

/// Steps the large files screen goes through.
public enum LargeFilesPhase: Equatable, Sendable {
    case intro
    case scanning
    case review
    case removing
    case finished(CleanupReport)
}
