import CleanMacCore
import Foundation

/// Gives every item the same size and remembers what it measured.
final class FixedSizeCalculator: SizeCalculating, @unchecked Sendable {
    let bytes: Int64
    private let lock = NSLock()
    private var urls: [URL] = []

    init(bytes: Int64) {
        self.bytes = bytes
    }

    var measured: [URL] {
        lock.withLock { urls }
    }

    func size(of url: URL) -> Int64 {
        lock.withLock { urls.append(url) }
        return bytes
    }
}
