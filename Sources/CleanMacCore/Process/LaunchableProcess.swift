import Foundation
import os

/// A subprocess that can be terminated from any thread, even before it has been launched.
final class LaunchableProcess: Sendable {
    private enum State {
        case idle, running, terminated
    }

    private let state = OSAllocatedUnfairLock(initialState: State.idle)
    private let process: Process

    init(_ process: Process) {
        self.process = process
    }

    /// Starts the process unless it was already terminated.
    func launch() throws {
        try state.withLock { state in
            guard state == .idle else { throw CancellationError() }
            try process.run()
            state = .running
        }
    }

    /// Stops the process if it is running and prevents a later launch.
    func terminate() {
        state.withLock { state in
            if state == .running { process.terminate() }
            state = .terminated
        }
    }
}
