import Foundation

/// Identity, creation date and number of names of a file on disk.
public struct FileMetadata: Hashable, Sendable {
    /// Device and inode. Hard links to the same file share it.
    public struct Identity: Hashable, Sendable {
        public let device: Int64
        public let inode: UInt64

        public init(device: Int64, inode: UInt64) {
            self.device = device
            self.inode = inode
        }
    }

    public let identity: Identity
    public let creationDate: Date?
    /// Names the file has on its volume, this one included: more than one when it has hard links.
    public let linkCount: Int

    public init(identity: Identity, creationDate: Date?, linkCount: Int = 1) {
        self.identity = identity
        self.creationDate = creationDate
        self.linkCount = linkCount
    }
}
