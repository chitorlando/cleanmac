import CleanMacCore
import Foundation

/// One copy inside a group of identical files.
public struct DuplicateFile: Identifiable, Hashable, Sendable {
    public let item: CleanableItem
    public let creationDate: Date?

    public var id: CleanableItem.ID { item.id }

    public init(item: CleanableItem, creationDate: Date?) {
        self.item = item
        self.creationDate = creationDate
    }
}
