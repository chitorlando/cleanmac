import CleanMacCore
import Foundation

/// One copy inside a group of identical files.
public struct DuplicateFile: Identifiable, Hashable, Sendable {
    public let item: CleanableItem
    public let creationDate: Date?
    /// How the copy shares its data with other files, or `nil` when its volume couldn't tell.
    public let cloneInfo: CloneInfo?

    public var id: CleanableItem.ID { item.id }

    /// Shares all of its data with another file, so removing it alone frees no space.
    ///
    /// `false` when its clones couldn't be counted, since nothing says the file has any.
    public var isClone: Bool { (cloneInfo?.cloneCount ?? 1) > 1 }

    public init(item: CleanableItem, creationDate: Date?, cloneInfo: CloneInfo?) {
        self.item = item
        self.creationDate = creationDate
        self.cloneInfo = cloneInfo
    }

    func withCloneInfo(_ cloneInfo: CloneInfo?) -> DuplicateFile {
        DuplicateFile(item: item, creationDate: creationDate, cloneInfo: cloneInfo)
    }
}
