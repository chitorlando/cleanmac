import Foundation

/// Read-only access to the structure of the file system.
public protocol DirectoryReading: Sendable {
    func itemExists(at url: URL) -> Bool
    func childItems(of directory: URL) throws -> [URL]
}
