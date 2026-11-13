import CleanMacCore
import Foundation

/// Answers what the test sets, and counts how often it was asked.
final class FakeFullDiskAccess: FullDiskAccessChecking, @unchecked Sendable {
    private let lock = NSLock()
    private var granted: Bool
    private var count = 0

    init(granted: Bool = false) {
        self.granted = granted
    }

    var checks: Int { locked { count } }

    func grant() { locked { granted = true } }
    func revoke() { locked { granted = false } }

    func hasFullDiskAccess() -> Bool {
        locked {
            count += 1
            return granted
        }
    }

    private func locked<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
