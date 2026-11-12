import Foundation

/// Gives the values of a fixed list one per read, repeating the last one once it runs out.
final class ReadingQueue<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [Value]

    init(_ values: [Value]) {
        self.values = values
    }

    func next() -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return values.count > 1 ? values.removeFirst() : values.first
    }
}
