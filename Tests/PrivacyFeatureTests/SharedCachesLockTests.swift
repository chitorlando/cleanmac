import CleanMacCore
import Foundation
import PrivacyFeature
import Testing

/// Caches listed under a browser can belong to another edition of it, with a bundle
/// identifier of its own. They must stay locked while that edition is open.
@MainActor
struct SharedCachesLockTests {
    private let folder: TemporaryFolder
    private let remover = RecordingRemover()
    private let runningApps = FakeRunningApps()

    init() throws {
        folder = try TemporaryFolder()
    }

    /// Scans the real catalog over the temporary Library and cleans what is selected by default.
    private func cleanAfterScanning(installed: [String: URL]) async {
        let scanner = BrowserCacheScanner(
            library: folder.url("Library"),
            appLocator: FakeAppLocator(apps: installed),
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator()
        )
        let viewModel = PrivacyViewModel(
            scanner: scanner,
            runningApps: runningApps,
            cleanupService: CleanupService(remover: remover)
        )
        await viewModel.startScan().value
        await viewModel.clean()?.value
    }

    /// Whether `file` is inside one of the folders the remover was asked to remove.
    private func wasRemoved(_ file: URL) -> Bool {
        let path = file.resolvingSymlinksInPath().path
        return remover.removed.contains(where: { path.hasPrefix($0.resolvingSymlinksInPath().path + "/") })
    }

    /// Firefox, Firefox Developer Edition and Firefox Nightly keep the caches of their
    /// profiles in the same `~/Library/Caches/Firefox/Profiles`.
    @Test func leavesOutTheCachesOfAnotherFirefoxEditionThatIsOpen() async throws {
        let firefox = try folder.make("Apps/Firefox.app/")
        try folder.make("Library/Caches/Firefox/Profiles/abc.default-release/cache2/entries/1", size: 10_000)
        let developerEditionCache = try folder.make(
            "Library/Caches/Firefox/Profiles/xyz.dev-edition-default/cache2/entries/1",
            size: 10_000
        )
        runningApps.running = [
            RunningApp(
                url: URL(filePath: "/Applications/Firefox Developer Edition.app"),
                bundleID: "org.mozilla.firefoxdeveloperedition"
            )
        ]

        await cleanAfterScanning(installed: ["org.mozilla.firefox": firefox])

        #expect(!wasRemoved(developerEditionCache))
    }

    /// "com.google.Chrome.canary" starts with Chrome's bundle identifier and a dot, so
    /// Chrome Canary's cache is listed under Chrome.
    @Test func leavesOutTheCacheNamedAfterAnotherEditionThatIsOpen() async throws {
        let chrome = try folder.make("Apps/Google Chrome.app/")
        try folder.make("Library/Caches/com.google.Chrome/Cache.db", size: 10_000)
        let canaryCache = try folder.make("Library/Caches/com.google.Chrome.canary/Cache.db", size: 10_000)
        runningApps.running = [
            RunningApp(url: URL(filePath: "/Applications/Google Chrome Canary.app"), bundleID: "com.google.Chrome.canary")
        ]

        await cleanAfterScanning(installed: ["com.google.Chrome": chrome])

        #expect(!wasRemoved(canaryCache))
    }
}
