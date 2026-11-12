import CleanMacCore

/// Steps the privacy screen goes through.
public enum PrivacyPhase: Equatable, Sendable {
    case intro
    case scanning
    case review
    case cleaning
    case finished(CleanupReport)
}
