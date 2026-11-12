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
///
/// Apps of `appsElsewhere` are only analyzed when the scan is asked to include them.
/// It can analyze those and the ones of its events, and no other.
struct StubAppScanner: InstalledAppScanning {
    let events: [AppScanEvent]
    var finishes = true
    var appsElsewhere: [InstalledApp] = []

    func scan(including otherApps: [URL]) -> AsyncStream<AppScanEvent> {
        let requestedPaths = Set(otherApps.map(\.standardizedFileURL.path))
        let requestedApps = appsElsewhere.filter { requestedPaths.contains($0.id.standardizedFileURL.path) }
        return AsyncStream { continuation in
            events.forEach { continuation.yield($0) }
            requestedApps.forEach { continuation.yield(.analyzed($0)) }
            if finishes { continuation.finish() }
        }
    }

    func canAnalyze(appAt url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        return (analyzedApps + appsElsewhere).contains { $0.id.standardizedFileURL.path == path }
    }

    private var analyzedApps: [InstalledApp] {
        events.compactMap { event in
            guard case .analyzed(let app) = event else { return nil }
            return app
        }
    }
}

/// Running apps kept in memory; quitting succeeds unless told otherwise.
///
/// The apps of `running` run from their own bundle. `runningElsewhere` has the ones that
/// don't, such as those the system runs from a random path.
@MainActor
final class FakeRunningApps: RunningAppsProviding {
    var running: Set<URL>
    var runningElsewhere: [RunningApp] = []
    var quitSucceeds = true
    private(set) var quitRequests: [URL] = []

    init(running: Set<URL> = []) {
        self.running = Set(running.map(\.standardizedFileURL))
    }

    func runningApps() -> [RunningApp] {
        running.map { RunningApp(url: $0, bundleID: nil) } + runningElsewhere
    }

    func quit(appAt url: URL) async -> Bool {
        quitRequests.append(url)
        guard quitSucceeds else { return false }
        running.remove(url.standardizedFileURL)
        runningElsewhere.removeAll { $0.url == url }
        return true
    }
}
