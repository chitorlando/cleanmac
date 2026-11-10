/// Items of a folder too small to show one by one in the disk map, counted together as “Other”.
public struct OtherItems: Equatable, Sendable {
    /// Files, packages and folders counted together.
    public private(set) var itemCount: Int
    /// Bytes they take up together.
    public private(set) var size: Int64
    /// Files inside them, counting each package as one file.
    public private(set) var fileCount: Int

    public init(itemCount: Int = 0, size: Int64 = 0, fileCount: Int = 0) {
        self.itemCount = itemCount
        self.size = size
        self.fileCount = fileCount
    }

    mutating func add(_ node: DiskNode) {
        itemCount += 1
        size += node.size
        fileCount += node.fileCount
    }
}
