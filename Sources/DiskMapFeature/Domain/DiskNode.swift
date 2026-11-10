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

    public var id: URL { url }
    public var name: String { url.lastPathComponent }

    public init(
        url: URL,
        kind: DiskNodeKind,
        size: Int64,
        fileCount: Int,
        children: [DiskNode] = [],
        otherItems: OtherItems? = nil
    ) {
        self.url = url
        self.kind = kind
        self.size = size
        self.fileCount = fileCount
        self.children = children
        self.otherItems = otherItems
    }

    /// A file or package found while walking a folder.
    public init(record: FileRecord) {
        self.init(url: record.url, kind: record.isPackage ? .package : .file, size: record.size, fileCount: 1)
    }
}
