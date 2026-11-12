import CleanMacCore
import Foundation
import os
import PrivacyFeature

/// `BrowserCacheScanning` that returns fixed results.
struct StubBrowserCacheScanner: BrowserCacheScanning {
    let results: [BrowserCaches]

    func scan() async -> [BrowserCaches] { results }
}

/// Removes nothing and remembers which URLs it was asked to remove.
final class RecordingRemover: ItemRemoving {
    private let removedURLs = OSAllocatedUnfairLock<[URL]>(initialState: [])

    var removed: [URL] { removedURLs.withLock { $0 } }

    func remove(_ url: URL) throws {
        removedURLs.withLock { $0.append(url) }
    }
}

/// Open apps kept in memory, by bundle identifier. Quitting succeeds unless told otherwise.
@MainActor
final class FakeRunningApps: RunningAppsProviding {
    var running: [RunningApp]
    var quitSucceeds = true
    private(set) var quitRequests: [URL] = []

    init(running: [RunningApp] = []) {
        self.running = running
    }

    func runningApps() -> [RunningApp] { running }

    func quit(appAt url: URL) async -> Bool {
        quitRequests.append(url)
        guard quitSucceeds else { return false }
        running.removeAll { $0.url == url }
        return true
    }
}

/// The caches of a browser of the catalog, with one item per name.
func browserCaches(_ name: String, bundleID: String, items: [String: Int64]) -> BrowserCaches {
    BrowserCaches(
        browser: BrowserDefinition(name: name, bundleID: bundleID, cacheLocations: []),
        appURL: URL(filePath: "/Applications/\(name).app"),
        items: items.map { CleanableItem(url: URL(filePath: "/home/Library/Caches/\(bundleID)/\($0.key)"), size: $0.value) }
    )
}
