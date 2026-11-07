import CleanMacCore

/// Steps the uninstaller screen goes through.
public enum UninstallerPhase: Equatable, Sendable {
    case intro
    case loading
    case browsing
    case uninstalling
    case finished(CleanupReport)
}
