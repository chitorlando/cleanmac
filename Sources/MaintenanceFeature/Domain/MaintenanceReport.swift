import Foundation

/// What happened to each task of a maintenance run, in the order they were chosen.
public struct MaintenanceReport: Equatable, Sendable {
    public let results: [MaintenanceTaskResult]

    public init(results: [MaintenanceTaskResult]) {
        self.results = results
    }

    public var failures: [MaintenanceTaskResult] {
        results.filter { $0.outcome != .succeeded }
    }
}
