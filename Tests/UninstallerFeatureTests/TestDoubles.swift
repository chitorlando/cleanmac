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

/// Returns a fixed list of apps regardless of the folders, and knows of others elsewhere.
struct FakeAppLocator: AppBundleLocating {
    let apps: [URL]
    var appsElsewhere: [URL] = []

    func applications(in folders: [URL]) -> [URL] { apps }

    func application(at url: URL) -> URL? {
        (apps + appsElsewhere).contains(url) ? url : nil
    }
}

/// Returns predefined identities keyed by app URL.
struct FakeAppInfoReader: AppInfoReading {
    let infos: [URL: AppBundleInfo]

    func info(forAppAt url: URL) -> AppBundleInfo? { infos[url] }
}

/// Emits a fixed list of scan events, optionally leaving the stream open.
struct StubAppScanner: InstalledAppScanning {
    let events: [AppScanEvent]
    var finishes = true

    func scan() -> AsyncStream<AppScanEvent> {
        AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            if finishes { continuation.finish() }
        }
    }
}

/// Running apps kept in memory; quitting succeeds unless told otherwise.
@MainActor
final class FakeRunningApps: RunningAppsProviding {
    var running: Set<URL>
    var quitSucceeds = true
    private(set) var quitRequests: [URL] = []

    init(running: Set<URL> = []) {
        self.running = Set(running.map(\.standardizedFileURL))
    }

    func runningAppURLs() -> Set<URL> { running }

    func quit(appAt url: URL) async -> Bool {
        quitRequests.append(url)
        guard quitSucceeds else { return false }
        running.remove(url.standardizedFileURL)
        return true
    }
}
