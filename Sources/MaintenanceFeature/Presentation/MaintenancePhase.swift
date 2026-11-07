import Foundation

/// Steps the maintenance screen goes through.
public enum MaintenancePhase: Equatable, Sendable {
    case choosing
    case running
    case finished(MaintenanceReport)
}
