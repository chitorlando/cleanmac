import CleanMacCore
import Foundation

/// A file that matches the large-file criteria, ready for the user to review.
public struct LargeFile: Identifiable, Hashable, Sendable {
    public let item: CleanableItem
    public let kind: FileKind
    /// When the file was last opened or, if unknown, last modified.
    public let lastAccessDate: Date?

    public var id: URL { item.url }

    public init(item: CleanableItem, kind: FileKind, lastAccessDate: Date?) {
        self.item = item
        self.kind = kind
        self.lastAccessDate = lastAccessDate
    }

    public init(record: FileRecord) {
        self.init(
            item: CleanableItem(url: record.url, size: record.size),
            kind: FileKind(url: record.url),
            lastAccessDate: record.lastAccessDate
        )
    }
}
