import Foundation

/// A uniquely named folder in the temporary directory, removed when the test ends.
final class TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "PrivacyFeatureTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    func url(_ path: String) -> URL {
        root.appending(path: path)
    }

    /// Creates a file of `size` bytes, or an empty folder when `path` ends with a slash, along with its parents.
    @discardableResult
    func make(_ path: String, size: Int = 1_000) throws -> URL {
        let url = url(path)
        if path.hasSuffix("/") {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } else {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(repeating: 1, count: size).write(to: url)
        }
        return url
    }
}
