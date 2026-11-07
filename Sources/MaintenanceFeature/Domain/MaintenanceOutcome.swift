import Foundation

/// How a single maintenance task ended.
public enum MaintenanceOutcome: Equatable, Sendable {
    case succeeded
    case failed(MaintenanceError)
}
