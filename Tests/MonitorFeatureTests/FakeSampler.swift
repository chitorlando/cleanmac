import Foundation
import MonitorFeature

/// Gives fixed snapshots, one per reading, and counts the readings.
final class FakeSampler: SystemSampling, @unchecked Sendable {
    private let snapshots: ReadingQueue<SystemSnapshot>
    private let lock = NSLock()
    private var count = 0

    init(_ snapshots: [SystemSnapshot]) {
        self.snapshots = ReadingQueue(snapshots)
    }

    var readings: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func sample() async -> SystemSnapshot {
        countReading()
        return snapshots.next() ?? SystemSnapshot()
    }

    private func countReading() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }
}
