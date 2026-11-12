import Foundation

/// A uniquely named folder in the temporary directory, removed when the test ends.
final class TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "LoginItemsFeatureTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    func url(_ path: String) -> URL {
        root.appending(path: path)
    }

    /// Creates an empty file, or a folder when `path` ends with a slash, along with its parents.
    @discardableResult
    func make(_ path: String) throws -> URL {
        let url = url(path)
        if path.hasSuffix("/") {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } else {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data().write(to: url)
        }
        return url
    }

    /// Writes a launchd property list with the given keys.
    @discardableResult
    func makePlist(_ path: String, _ keys: [String: Any], format: PropertyListSerialization.PropertyListFormat = .xml) throws -> URL {
        let url = url(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try PropertyListSerialization.data(fromPropertyList: keys, format: format, options: 0).write(to: url)
        return url
    }
}
