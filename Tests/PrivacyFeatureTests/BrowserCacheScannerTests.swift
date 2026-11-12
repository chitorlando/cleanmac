import CleanMacCore
import Foundation
import PrivacyFeature
import Testing

struct BrowserCacheScannerTests {
    private let folder: TemporaryFolder

    init() throws {
        folder = try TemporaryFolder()
    }

    private func scan(installed: [String: URL]) async -> [BrowserCaches] {
        await BrowserCacheScanner(
            library: folder.url("Library"),
            appLocator: FakeAppLocator(apps: installed),
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator()
        ).scan()
    }

    @Test func listsTheCachesOfInstalledBrowsersLargestFirst() async throws {
        let chrome = try folder.make("Apps/Google Chrome.app/")
        try folder.make("Library/Caches/Google/Chrome/Default/Cache/data", size: 10_000)
        try folder.make("Library/Application Support/Google/Chrome/Default/Code Cache/js", size: 200_000)
        try folder.make("Library/Application Support/Google/Chrome/Default/History", size: 500_000)

        let results = await scan(installed: ["com.google.Chrome": chrome])

        #expect(results.map(\.name) == ["Google Chrome"])
        #expect(results.first?.appURL == chrome)
        #expect(results.first?.items.map(\.name) == ["Code Cache", "Chrome"])
    }

    @Test func leavesOutBrowsersThatAreNotInstalled() async throws {
        try folder.make("Library/Caches/Firefox/Profiles/abc/cache2/entries", size: 10_000)

        #expect(await scan(installed: [:]).isEmpty)
    }

    @Test func leavesOutDeletedApps() async throws {
        try folder.make("Library/Caches/Firefox/Profiles/abc/cache2/entries", size: 10_000)

        #expect(await scan(installed: ["org.mozilla.firefox": folder.url("Apps/Firefox.app")]).isEmpty)
    }

    @Test func leavesOutBrowsersWithoutCachesAndEmptyFolders() async throws {
        let firefox = try folder.make("Apps/Firefox.app/")
        try folder.make("Library/Caches/Firefox/Profiles/abc/cache2/")

        #expect(await scan(installed: ["org.mozilla.firefox": firefox]).isEmpty)
    }
}
