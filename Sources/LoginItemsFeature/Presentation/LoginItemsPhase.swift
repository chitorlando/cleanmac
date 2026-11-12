import CleanMacCore

/// Steps the login items screen goes through.
public enum LoginItemsPhase: Equatable, Sendable {
    case intro
    case loading
    case browsing
    case removing
    case finished(CleanupReport)
}
