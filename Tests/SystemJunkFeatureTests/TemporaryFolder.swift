import Foundation

/// A uniquely named folder in the temporary directory, removed when the test ends.
final class TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "SystemJunkFeatureTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    /// Creates a folder at `path`, relative to the root, along with the folders that lead to it.
    @discardableResult
    func makeFolder(_ path: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Creates a file of `size` bytes at `path`, relative to the root, along with its folders.
    @discardableResult
    func makeFile(_ path: String, size: Int = 1_000) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(repeating: 1, count: size).write(to: url)
        return url
    }

    /// Gives the item at `path`, relative to the root, the POSIX permissions `mode`, such as
    /// `0` to keep everyone out but root.
    func setPermissions(_ path: String, to mode: Int) throws {
        let url = root.appending(path: path)
        try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path(percentEncoded: false))
    }
}
