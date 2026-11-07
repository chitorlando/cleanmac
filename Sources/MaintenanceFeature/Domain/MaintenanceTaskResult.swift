import Foundation

/// The outcome of one task in a maintenance run.
public struct MaintenanceTaskResult: Equatable, Sendable {
    public let task: MaintenanceTaskKind
    public let outcome: MaintenanceOutcome

    public init(task: MaintenanceTaskKind, outcome: MaintenanceOutcome) {
        self.task = task
        self.outcome = outcome
    }
}
