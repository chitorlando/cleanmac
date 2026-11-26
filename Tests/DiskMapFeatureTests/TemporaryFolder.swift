import Foundation

/// A uniquely named folder in the temporary directory, removed when the test ends.
final class TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "DiskMapFeatureTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    /// Hides the item at `path`, relative to the root, the way Finder does: without a dot in its name.
    func hide(_ path: String) throws {
        var url = root.appending(path: path)
        var values = URLResourceValues()
        values.isHidden = true
        try url.setResourceValues(values)
    }

    /// Gives the item at `path`, relative to the root, the POSIX permissions `mode`, such as
    /// `0` to keep everyone out but root.
    @discardableResult
    func setPermissions(_ path: String, to mode: Int) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: url.path(percentEncoded: false))
        return url
    }

    /// Creates a file of `size` bytes at `path`, relative to the root, along with its folders.
    @discardableResult
    func makeFile(_ path: String, size: Int = 1_000) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(repeating: 1, count: size).write(to: url)
        return url
    }

    /// Space the files at `paths` take up on disk, which is what the map adds up.
    func allocatedSize(of paths: String...) throws -> Int64 {
        try paths.reduce(0) { total, path in
            let values = try root.appending(path: path).resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            return total + Int64(values.totalFileAllocatedSize ?? 0)
        }
    }
}
