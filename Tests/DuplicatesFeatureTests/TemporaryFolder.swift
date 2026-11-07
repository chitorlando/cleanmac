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
    func makeHardLink(_ path: String, to existing: URL) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.linkItem(at: existing, to: url)
        return url
    }
}

extension Data {
    /// Deterministic content that differs for each seed.
    static func pattern(count: Int, seed: UInt8) -> Data {
        Data((0..<count).map { UInt8(truncatingIfNeeded: $0 &* 31 &+ Int(seed) &* 7) ^ seed })
    }
}
