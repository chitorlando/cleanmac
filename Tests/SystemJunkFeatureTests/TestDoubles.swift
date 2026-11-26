import CleanMacCore
import Foundation
import os
import SystemJunkFeature

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

/// Returns a fixed result for one category.
struct StubJunkScanner: JunkScanner {
    let result: CategoryScanResult

    var category: JunkCategory { result.category }

    init(category: JunkCategory, items: [CleanableItem]) {
        result = CategoryScanResult(category: category, items: items)
    }

    init(result: CategoryScanResult) {
        self.result = result
    }

    func scan() async -> CategoryScanResult { result }
}

/// Removes nothing and remembers which URLs it was asked to remove.
final class RecordingRemover: ItemRemoving {
    private let removedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])

    var removed: [URL] { removedURLs.withLock { $0 } }

    func remove(_ url: URL) throws {
        removedURLs.withLock { $0.append(url) }
    }
}

/// Open apps kept in memory. None of them quits.
@MainActor
final class FakeRunningApps: RunningAppsProviding {
    var running: [RunningApp] = []

    func runningApps() -> [RunningApp] { running }

    func quit(appAt url: URL) async -> Bool { false }
}
