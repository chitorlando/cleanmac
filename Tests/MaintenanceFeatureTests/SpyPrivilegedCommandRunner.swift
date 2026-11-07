@testable import MaintenanceFeature
import Foundation

/// Records every batch it is asked to run and optionally fails all of them.
actor SpyPrivilegedCommandRunner: PrivilegedCommandRunning {
    private let error: (any Error)?
    private(set) var batches: [[ShellCommand]] = []

    init(throwing error: (any Error)? = nil) {
        self.error = error
    }

    func run(_ commands: [ShellCommand]) async throws {
        batches.append(commands)
        if let error { throw error }
    }
}
