import CleanMacCore
import Foundation
import UninstallerFeature

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

/// Returns a fixed list of apps regardless of the folders.
struct FakeAppLocator: AppBundleLocating {
    let apps: [URL]

    func applications(in folders: [URL]) -> [URL] { apps }
}

/// Returns predefined identities keyed by app URL.
struct FakeAppInfoReader: AppInfoReading {
    let infos: [URL: AppBundleInfo]

    func info(forAppAt url: URL) -> AppBundleInfo? { infos[url] }
}
