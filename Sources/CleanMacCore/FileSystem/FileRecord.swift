import Foundation

/// A regular file found while walking a folder, with the metadata needed to judge it.
///
/// It can also be a whole package, such as an app, when the walker is asked to measure them.
public struct FileRecord: Hashable, Sendable {
    public let url: URL
    /// Space allocated on disk, which is what removing the file frees.
    public let size: Int64
    /// When the file was last opened or, if unknown, last modified.
    public let lastAccessDate: Date?
    /// The record is a package, such as an `.app`, measured as a single file with all its contents.
    public let isPackage: Bool

    public init(url: URL, size: Int64, accessDate: Date?, modificationDate: Date?, isPackage: Bool = false) {
        self.url = url
        self.size = size
        self.lastAccessDate = accessDate ?? modificationDate
        self.isPackage = isPackage
    }
}
