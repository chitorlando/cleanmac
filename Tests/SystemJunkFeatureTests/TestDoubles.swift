import CleanMacCore
import Foundation

/// In-memory file tree: each folder maps to its children.
struct FakeDirectoryReader: DirectoryReading {
    let tree: [URL: [URL]]

    func itemExists(at url: URL) -> Bool { tree[url] != nil }

    func childItems(of directory: URL) throws -> [URL] { tree[directory] ?? [] }
}

/// Returns predefined sizes.
struct FakeSizeCalculator: SizeCalculating {
    let sizes: [URL: Int64]

    func size(of url: URL) -> Int64 { sizes[url] ?? 0 }
}
