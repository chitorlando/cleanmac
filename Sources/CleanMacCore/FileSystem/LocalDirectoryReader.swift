import Foundation

/// `DirectoryReading` backed by the local disk.
public struct LocalDirectoryReader: DirectoryReading {
    public init() {}

    public func itemExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func childItems(of directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )
    }
}
