import CleanMacCore
import Foundation

/// One copy inside a group of identical files.
public struct DuplicateFile: Identifiable, Hashable, Sendable {
    public let item: CleanableItem
    public let creationDate: Date?
    /// How the copy shares its data with other files, or `nil` when its volume couldn't tell.
    public let cloneInfo: CloneInfo?
    /// Names the file has on its volume, this one included: more than one when it has hard links.
    public let linkCount: Int

    public var id: CleanableItem.ID { item.id }

    /// Shares all of its data with another file, so removing it alone frees no space.
    ///
    /// `false` when its clones couldn't be counted, since nothing says the file has any:
    /// only its group can then tell, by its other copies (see `DuplicateGroup.isClone(_:)`).
    public var isClone: Bool { (cloneInfo?.cloneCount ?? 1) > 1 }

    /// Has names its group doesn't hold, so its data stays on disk after this copy is removed.
    ///
    /// A group holds one name of each file: hard links to the same file are never reported as
    /// copies, wherever the other names are.
    public var hasOtherNames: Bool { linkCount > 1 }

    public init(item: CleanableItem, creationDate: Date?, cloneInfo: CloneInfo?, linkCount: Int = 1) {
        self.item = item
        self.creationDate = creationDate
        self.cloneInfo = cloneInfo
        self.linkCount = linkCount
    }

    func withCloneInfo(_ cloneInfo: CloneInfo?) -> DuplicateFile {
        DuplicateFile(item: item, creationDate: creationDate, cloneInfo: cloneInfo, linkCount: linkCount)
    }
}
