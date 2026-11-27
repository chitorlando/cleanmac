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

    /// Records that emptying the Trash failed, so what `bins` held is still there.
    mutating func recordTrashNotEmptied(_ bins: [CleanableItem], error: any Error) {
        let kind = CleanupFailureClassifier.kind(of: error)
        failures += bins.map { bin in
            CleanupFailure(item: bin, kind: kind, reason: error.localizedDescription, isTrashBin: true)
        }
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
    /// Whether the item is a Trash bin that couldn't be emptied, rather than an item that
    /// couldn't be moved to the Trash.
    public let isTrashBin: Bool

    public init(item: CleanableItem, kind: CleanupFailureKind, reason: String, isTrashBin: Bool = false) {
        self.item = item
        self.kind = kind
        self.reason = reason
        self.isTrashBin = isTrashBin
    }
}

public extension Sequence where Element == CleanupFailure {
    /// Whether any item failed because macOS protects it, so Full Disk Access may help. It
    /// doesn't for a Trash bin, which Finder empties, not CleanMac.
    var includesProtectedItems: Bool {
        contains { $0.kind == .protectedByMacOS && !$0.isTrashBin }
    }

    /// Whether anything failed because CleanMac isn't allowed to control Finder, so allowing it
    /// in the Automation settings may help.
    var includesFinderAutomationDenials: Bool {
        contains { $0.kind == .finderAutomationDenied }
    }

    /// Whether the Trash couldn't be emptied, which fails for all its bins at once.
    var includesTrashBins: Bool {
        contains { $0.isTrashBin }
    }

    /// How many items couldn't be moved to the Trash, leaving out the Trash bins that couldn't
    /// be emptied.
    var unmovedItemCount: Int {
        filter { !$0.isTrashBin }.count
    }
}
