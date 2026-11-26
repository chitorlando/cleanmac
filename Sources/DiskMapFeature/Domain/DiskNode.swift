import CleanMacCore
import Foundation

/// One item of the disk map, with the space it takes up and, for folders, what's inside.
public struct DiskNode: Identifiable, Equatable, Sendable {
    public let url: URL
    public let kind: DiskNodeKind
    /// Bytes allocated on disk by the item and everything inside it.
    public let size: Int64
    /// Files inside the item, counting each package as one file. A file counts itself.
    public let fileCount: Int
    /// Items inside a folder, largest first. Files and packages have none.
    public let children: [DiskNode]
    /// Items of a folder too small to show one by one, counted together.
    public let otherItems: OtherItems?
    /// The folder couldn't be read, such as one macOS keeps private, so what it holds isn't
    /// known: it counts as empty here, though it probably isn't.
    public let isUnreadable: Bool
    /// Folders that couldn't be read inside the item, itself included. When there are any,
    /// the item takes up more space than its size says.
    public let unreadableFolderCount: Int

    public var id: URL { url }
    public var name: String { url.lastPathComponent }

    public init(
        url: URL,
        kind: DiskNodeKind,
        size: Int64,
        fileCount: Int,
        children: [DiskNode] = [],
        otherItems: OtherItems? = nil,
        isUnreadable: Bool = false
    ) {
        self.url = url
        self.kind = kind
        self.size = size
        self.fileCount = fileCount
        self.children = children
        self.otherItems = otherItems
        self.isUnreadable = isUnreadable
        unreadableFolderCount = children.reduce(isUnreadable ? 1 : 0) { $0 + $1.unreadableFolderCount }
    }

    /// A file or package found while walking a folder.
    public init(record: FileRecord) {
        self.init(url: record.url, kind: record.isPackage ? .package : .file, size: record.size, fileCount: 1)
    }

    /// Order of the children: largest first, and items of the same size by name, as Finder sorts them.
    static func isLarger(_ lhs: DiskNode, _ rhs: DiskNode) -> Bool {
        guard lhs.size == rhs.size else { return lhs.size > rhs.size }
        switch lhs.name.localizedStandardCompare(rhs.name) {
        case .orderedAscending: return true
        case .orderedDescending: return false
        case .orderedSame: return lhs.url.path < rhs.url.path
        }
    }
}
