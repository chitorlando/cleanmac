import Foundation

/// Runs a set of maintenance tasks and reports how each one ended.
public protocol MaintenanceRunning: Sendable {
    func run(_ tasks: [MaintenanceTaskKind]) async -> MaintenanceReport
}
