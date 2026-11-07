import CleanMacCore

/// Files with identical contents.
public struct DuplicateGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let files: [DuplicateFile]
    /// Space each copy occupies on disk.
    public let fileSize: Int64

    /// Space freed by keeping a single copy.
    public var recoverableSize: Int64 { fileSize * Int64(max(files.count - 1, 0)) }

    /// Name of the first copy, to label the group.
    public var name: String { files.first?.item.name ?? "" }

    public var items: [CleanableItem] { files.map(\.item) }

    public init(id: String, files: [DuplicateFile], fileSize: Int64) {
        self.id = id
        self.files = files
        self.fileSize = fileSize
    }
}
