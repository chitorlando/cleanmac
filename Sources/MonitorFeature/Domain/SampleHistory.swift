/// The latest values of a measure, up to a fixed number, oldest first.
///
/// A ring buffer: once full, each new value takes the place of the oldest one.
public struct SampleHistory<Value: Sendable>: Sendable {
    public let capacity: Int
    private var storage: [Value] = []
    /// Where the oldest value is, once the buffer is full.
    private var start = 0

    public init(capacity: Int) {
        self.capacity = max(capacity, 1)
        storage.reserveCapacity(self.capacity)
    }

    public var count: Int { storage.count }
    public var isEmpty: Bool { storage.isEmpty }

    /// The values kept, oldest first.
    public var values: [Value] {
        Array(storage[start...] + storage[..<start])
    }

    public var latest: Value? {
        guard !storage.isEmpty else { return nil }
        return storage[(start + storage.count - 1) % storage.count]
    }

    public mutating func append(_ value: Value) {
        if storage.count < capacity {
            storage.append(value)
        } else {
            storage[start] = value
            start = (start + 1) % capacity
        }
    }
}
