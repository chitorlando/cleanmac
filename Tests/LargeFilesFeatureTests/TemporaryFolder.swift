import Foundation

/// A uniquely named folder in the temporary directory, removed when the test ends.
final class TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "LargeFilesFeatureTests-\(UUID().uuidString)")
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

    /// Creates a symbolic link at `path` that points to `destination`, both relative to the root.
    @discardableResult
    func makeLink(_ path: String, to destination: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: root.appending(path: destination))
        return url
    }

    /// Creates a file of `size` bytes at `path`, relative to the root, along with its folders.
    @discardableResult
    func makeFile(_ path: String, size: Int = 1_000, accessDate: Date? = nil) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(repeating: 1, count: size).write(to: url)
        if let accessDate {
            var values = URLResourceValues()
            values.contentAccessDate = accessDate
            var mutableURL = url
            try mutableURL.setResourceValues(values)
        }
        return url
    }
}
