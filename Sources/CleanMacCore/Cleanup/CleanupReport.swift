import Foundation

/// Outcome of a cleanup: what was removed and what could not be.
public struct CleanupReport: Equatable, Sendable {
    public private(set) var freedBytes: Int64 = 0
    public private(set) var removedCount = 0
    public private(set) var failures: [CleanupFailure] = []

    public init() {}

    mutating func recordSuccess(_ item: CleanableItem) {
        freedBytes += item.size
        removedCount += 1
    }

    mutating func recordFailure(_ item: CleanableItem, error: any Error) {
        failures.append(CleanupFailure(item: item, reason: error.localizedDescription))
    }
}

public struct CleanupFailure: Equatable, Sendable {
    public let item: CleanableItem
    public let reason: String
}
