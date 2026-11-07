import Foundation

/// A throwaway folder in the system temporary directory, so tests never touch the user's disk.
struct TemporaryFolder {
    let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    @discardableResult
    func makeFolder(_ path: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    func makeLink(_ path: String, to destination: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: root.appending(path: destination))
        return url
    }

    @discardableResult
    func writePlist(_ properties: [String: Any], to path: String) throws -> URL {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: 0)
        try data.write(to: url)
        return url
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}
