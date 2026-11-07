/// How far a duplicate scan has gone.
public struct DuplicateScanProgress: Hashable, Sendable {
    /// Files looked at while walking the folder.
    public var scannedFiles: Int
    /// Bytes read so far to compare file contents.
    public var hashedBytes: Int64

    public init(scannedFiles: Int = 0, hashedBytes: Int64 = 0) {
        self.scannedFiles = scannedFiles
        self.hashedBytes = hashedBytes
    }
}
