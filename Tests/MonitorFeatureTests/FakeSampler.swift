import Foundation
import MonitorFeature

/// Gives fixed snapshots, one per reading, and notes every call in order.
final class FakeSampler: SystemSampling, @unchecked Sendable {
    enum Call: Equatable {
        case sample, forgetPreviousReading
    }

    private let snapshots: ReadingQueue<SystemSnapshot>
    private let lock = NSLock()
    private var log: [Call] = []

    init(_ snapshots: [SystemSnapshot]) {
        self.snapshots = ReadingQueue(snapshots)
    }

    /// Every call so far, oldest first.
    var calls: [Call] {
        lock.lock()
        defer { lock.unlock() }
        return log
    }

    var readings: Int {
        calls.filter { $0 == .sample }.count
    }

    func sample() async -> SystemSnapshot {
        note(.sample)
        return snapshots.next() ?? SystemSnapshot()
    }

    func forgetPreviousReading() async {
        note(.forgetPreviousReading)
    }

    private func note(_ call: Call) {
        lock.lock()
        defer { lock.unlock() }
        log.append(call)
    }
}
