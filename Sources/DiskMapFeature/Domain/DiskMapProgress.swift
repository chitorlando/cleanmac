import CleanMacCore

/// How far a disk map scan has gone.
public struct DiskMapProgress: Hashable, Sendable {
    /// Files measured so far, counting each package as one file.
    public private(set) var fileCount: Int
    /// Bytes they take up on disk.
    public private(set) var byteCount: Int64

    public init(fileCount: Int = 0, byteCount: Int64 = 0) {
        self.fileCount = fileCount
        self.byteCount = byteCount
    }

    mutating func add(_ record: FileRecord) {
        fileCount += 1
        byteCount += record.size
    }
}
