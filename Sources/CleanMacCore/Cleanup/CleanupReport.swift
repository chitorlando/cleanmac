import Foundation

/// Outcome of a cleanup: what was removed and what could not be.
public struct CleanupReport: Equatable, Sendable {
    public private(set) var freedBytes: Int64 = 0
    /// Items moved to the Trash.
    public private(set) var removedCount = 0
    /// Whether the Trash was emptied, which erased what it held for good.
    public private(set) var emptiedTrash = false
    public private(set) var failures: [CleanupFailure] = []

    public init() {}

    mutating func recordSuccess(_ item: CleanableItem) {
        freedBytes += item.size
        removedCount += 1
    }

    /// Records that emptying the Trash freed what `bins` held.
    mutating func recordEmptiedTrash(_ bins: [CleanableItem]) {
        freedBytes += bins.totalSize
        emptiedTrash = true
    }

    /// Adds what another cleanup of the same batch did, such as moving items to the Trash
    /// after emptying it.
    public mutating func merge(_ other: CleanupReport) {
        freedBytes += other.freedBytes
        removedCount += other.removedCount
        emptiedTrash = emptiedTrash || other.emptiedTrash
        failures += other.failures
    }

    mutating func recordFailure(_ item: CleanableItem, error: any Error) {
        failures.append(CleanupFailure(
            item: item,
            kind: CleanupFailureClassifier.kind(of: error),
            reason: error.localizedDescription
        ))
    }
}

/// An item that couldn't be moved to the Trash, or a Trash bin that couldn't be emptied.
public struct CleanupFailure: Equatable, Sendable {
    public let item: CleanableItem
    /// Why, in terms the user can act on.
    public let kind: CleanupFailureKind
    /// The system's own description of the error. It's technical and may mix languages,
    /// so it's only shown as a detail, never as the message.
    public let reason: String

    public init(item: CleanableItem, kind: CleanupFailureKind, reason: String) {
        self.item = item
        self.kind = kind
        self.reason = reason
    }
}

public extension Sequence where Element == CleanupFailure {
    /// Whether any item failed because macOS protects it, so Full Disk Access may help.
    var includesProtectedItems: Bool {
        contains { $0.kind == .protectedByMacOS }
    }
}
