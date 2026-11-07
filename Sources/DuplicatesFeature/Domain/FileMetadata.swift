import Foundation

/// Identity and creation date of a file on disk.
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

    public init(identity: Identity, creationDate: Date?) {
        self.identity = identity
        self.creationDate = creationDate
    }
}
