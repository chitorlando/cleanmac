@testable import MaintenanceFeature
import Foundation

/// Records every batch it is asked to run. It answers with the configured outcomes,
/// success for every job by default, or fails the whole batch.
actor SpyPrivilegedCommandRunner: PrivilegedCommandRunning {
    private let outcomes: [MaintenanceOutcome]?
    private let error: (any Error)?
    private(set) var batches: [[[ShellCommand]]] = []

    init(outcomes: [MaintenanceOutcome]? = nil, throwing error: (any Error)? = nil) {
        self.outcomes = outcomes
        self.error = error
    }

    func run(_ jobs: [[ShellCommand]]) async throws -> [MaintenanceOutcome] {
        batches.append(jobs)
        if let error { throw error }
        return outcomes ?? Array(repeating: .succeeded, count: jobs.count)
    }
}
