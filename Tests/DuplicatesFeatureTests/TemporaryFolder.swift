import Darwin
import Foundation

/// A uniquely named folder in the temporary directory, removed when the test ends.
final class TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "DuplicatesFeatureTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    /// Writes `data` at `path`, relative to the root, creating its folders.
    @discardableResult
    func write(_ data: Data, to path: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
        return url
    }

    @discardableResult
    func makeFolder(_ path: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Makes a symbolic link at `path` that points to `destination`.
    @discardableResult
    func makeSymbolicLink(_ path: String, to destination: URL) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: destination)
        return url
    }

    /// Hides the item at `path` the way Finder does, without a dot in its name.
    func hide(_ path: String) throws {
        var url = root.appending(path: path)
        var values = URLResourceValues()
        values.isHidden = true
        try url.setResourceValues(values)
    }

    @discardableResult
    func makeHardLink(_ path: String, to existing: URL) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.linkItem(at: existing, to: url)
        return url
    }

    /// Makes an APFS clone of `existing` at `path` with `clonefile(2)`: a new file that shares its data.
    @discardableResult
    func makeClone(_ path: String, of existing: URL) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard clonefile(existing.path, url.path, 0) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        return url
    }

    /// Overwrites the first bytes of the file at `url` without replacing the file.
    func overwriteStart(of url: URL, with data: Data) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.write(contentsOf: data)
    }
}

extension Data {
    /// Deterministic content that differs for each seed.
    static func pattern(count: Int, seed: UInt8) -> Data {
        Data((0..<count).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ Int(seed) &* 7) ^ seed })
    }
}
