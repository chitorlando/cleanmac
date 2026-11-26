import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

@MainActor
struct SystemJunkViewModelTests {
    private let item = CleanableItem(url: URL(filePath: "/home/Library/Caches/com.example.app"), size: 42)
    private let vivaldiCache = CleanableItem(url: URL(filePath: "/home/Library/Caches/Vivaldi"), size: 5_900)
    private let vivaldiNamedCache = CleanableItem(url: URL(filePath: "/home/Library/Caches/com.vivaldi.Vivaldi"), size: 300)
    private let log = CleanableItem(url: URL(filePath: "/home/Library/Logs/Vivaldi"), size: 7)
    private let openVivaldi = RunningApp(url: URL(filePath: "/Applications/Vivaldi.app"), bundleID: "com.vivaldi.Vivaldi")
    private let runningApps = FakeRunningApps()
    private let remover = RecordingRemover()

    private func makeViewModel(remover: any ItemRemoving, scanners: [any JunkScanner]? = nil) -> SystemJunkViewModel {
        SystemJunkViewModel(
            scanService: JunkScanService(scanners: scanners ?? [
                StubJunkScanner(category: .userCaches, items: [vivaldiCache, vivaldiNamedCache, item]),
                StubJunkScanner(category: .userLogs, items: [log])
            ]),
            cleanupService: CleanupService(remover: remover),
            runningApps: runningApps,
            cacheUsage: BrowserCacheUsage(library: URL(filePath: "/home/Library"))
        )
    }

    private func scannedViewModel() async -> SystemJunkViewModel {
        let viewModel = makeViewModel(remover: remover)
        await viewModel.startScan().value
        return viewModel
    }

    @Test func askingToCleanRemovesNothing() async {
        let viewModel = await scannedViewModel()

        viewModel.requestClean()

        #expect(viewModel.isConfirmingClean)
        #expect(viewModel.selectedCount == 4)
        #expect(viewModel.phase == .review)
        #expect(remover.removed.isEmpty)
    }

    @Test func asksNothingWithoutASelection() async {
        let viewModel = await scannedViewModel()
        for found in [vivaldiCache, vivaldiNamedCache, item, log] {
            viewModel.toggle(found)
        }

        viewModel.requestClean()

        #expect(!viewModel.isConfirmingClean)
    }

    @Test func cancellingTheCleanupRemovesNothing() async {
        let viewModel = await scannedViewModel()
        viewModel.requestClean()

        viewModel.cancelClean()

        #expect(!viewModel.isConfirmingClean)
        #expect(viewModel.phase == .review)
        #expect(viewModel.hasSelection)
        #expect(remover.removed.isEmpty)
    }

    @Test func confirmingCleansAndStopsAsking() async {
        let viewModel = await scannedViewModel()
        viewModel.requestClean()

        await viewModel.clean()?.value

        #expect(!viewModel.isConfirmingClean)
        #expect(Set(remover.removed) == [vivaldiCache.url, vivaldiNamedCache.url, item.url, log.url])
    }

    @Test func asksOnlyAboutWhatNoBrowserOpenedSinceTheScanIsUsing() async {
        let viewModel = await scannedViewModel()
        runningApps.running = [openVivaldi]

        viewModel.requestClean()

        #expect(viewModel.isConfirmingClean)
        #expect(viewModel.selectedCount == 2)
        #expect(remover.removed.isEmpty)
    }

    private func cachesCategory(of viewModel: SystemJunkViewModel) throws -> CategoryScanResult {
        try #require(viewModel.results.first(where: { $0.category == .userCaches }))
    }

    @Test func selectsEverythingWhenNoBrowserIsOpen() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.selectedSize == viewModel.foundSize)
        #expect(viewModel.selectedItems.count == 4)
    }

    @Test func showsACategoryMacOSKeepsCleanMacOutOfWithNothingToSelect() async {
        let viewModel = makeViewModel(remover: remover, scanners: [
            StubJunkScanner(result: .unreadable(.userLogs)),
            StubJunkScanner(category: .userCaches, items: [])
        ])

        await viewModel.startScan().value

        #expect(viewModel.phase == .review)
        #expect(viewModel.results.map(\.category) == [.userLogs])
        #expect(viewModel.results.allSatisfy(\.needsFullDiskAccess))
        #expect(viewModel.foundSize == 0)
        #expect(!viewModel.hasSelection)
    }

    @Test func locksTheCachesOfAnOpenBrowser() async throws {
        runningApps.running = [openVivaldi]
        let viewModel = await scannedViewModel()
        let caches = try cachesCategory(of: viewModel)

        viewModel.toggle(vivaldiCache)
        viewModel.toggle(caches)
        viewModel.toggle(caches)

        #expect(!viewModel.canSelect(vivaldiCache))
        #expect(!viewModel.canSelect(vivaldiNamedCache))
        #expect(!viewModel.isSelected(vivaldiCache))
        #expect(viewModel.openApps(using: vivaldiCache) == [openVivaldi])
        #expect(viewModel.openApps(lockingItemsOf: caches) == [openVivaldi])
        #expect(viewModel.selectionState(of: caches) == .all)
        #expect(Set(viewModel.selectedItems) == [item, log])
        #expect(viewModel.foundSize == 6_249)
        #expect(viewModel.selectedSize == 49)
    }

    @Test func leavesOutTheCachesOfABrowserOpenedBeforeCleaning() async {
        let viewModel = await scannedViewModel()
        runningApps.running = [openVivaldi]

        await viewModel.clean()?.value

        #expect(Set(remover.removed) == [item.url, log.url])
    }

    @Test func unlocksTheCachesOnceTheBrowserQuitsWithoutSelectingThem() async {
        runningApps.running = [openVivaldi]
        let viewModel = await scannedViewModel()

        runningApps.running = []
        viewModel.refreshOpenApps()

        #expect(viewModel.canSelect(vivaldiCache))
        #expect(!viewModel.isSelected(vivaldiCache))

        viewModel.toggle(vivaldiCache)

        #expect(viewModel.isSelected(vivaldiCache))
    }

    @Test func cleansNothingWhenEverythingSelectedIsLocked() async {
        runningApps.running = [openVivaldi]
        let viewModel = await scannedViewModel()
        viewModel.toggle(item)
        viewModel.toggle(log)

        #expect(!viewModel.hasSelection)
        #expect(viewModel.clean() == nil)
        #expect(remover.removed.isEmpty)
    }

    @Test func restartingDuringACleanupIgnoresItsResult() async {
        let remover = BlockingRemover()
        let viewModel = makeViewModel(remover: remover)
        await viewModel.startScan().value

        let cleanup = viewModel.clean()
        await remover.waitUntilRemoving()
        await viewModel.startScan().value
        remover.release()
        await cleanup?.value

        #expect(viewModel.phase == .review)
    }
}
