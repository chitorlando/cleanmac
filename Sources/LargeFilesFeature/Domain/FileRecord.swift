import Foundation

/// A regular file found while walking a folder, with the metadata needed to judge it.
public struct FileRecord: Hashable, Sendable {
    public let url: URL
    /// Space allocated on disk, which is what removing the file frees.
    public let size: Int64
    /// When the file was last opened or, if unknown, last modified.
    public let lastAccessDate: Date?

    public init(url: URL, size: Int64, accessDate: Date?, modificationDate: Date?) {
        self.url = url
        self.size = size
        self.lastAccessDate = accessDate ?? modificationDate
    }
}
