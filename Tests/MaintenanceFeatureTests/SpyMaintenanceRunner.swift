@testable import MaintenanceFeature
import Foundation

/// Records the tasks it is asked to run and reports them all as succeeded.
/// With `waitsForCancellation`, it holds the run until the calling task is cancelled.
actor SpyMaintenanceRunner: MaintenanceRunning {
    private let waitsForCancellation: Bool
    private(set) var requests: [[MaintenanceTaskKind]] = []

    init(waitsForCancellation: Bool = false) {
        self.waitsForCancellation = waitsForCancellation
    }

    func run(_ tasks: [MaintenanceTaskKind]) async -> MaintenanceReport {
        requests.append(tasks)
        if waitsForCancellation {
            try? await Task.sleep(for: .seconds(60))
        }
        return MaintenanceReport(results: tasks.map { MaintenanceTaskResult(task: $0, outcome: .succeeded) })
    }
}
