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
    private let homeBin = CleanableItem(url: URL(filePath: "/home/.Trash", directoryHint: .isDirectory), size: 3_000)
    private let diskBin = CleanableItem(url: URL(filePath: "/Volumes/Disk/.Trashes/501", directoryHint: .isDirectory), size: 500)
    private let runningApps = FakeRunningApps()
    private let remover = RecordingRemover()
    private let emptier: RecordingTrashEmptier

    init() {
        emptier = RecordingTrashEmptier(remover: remover)
    }

    private func makeViewModel(remover: any ItemRemoving, scanners: [any JunkScanner]? = nil) -> SystemJunkViewModel {
        SystemJunkViewModel(
            scanService: JunkScanService(scanners: scanners ?? [
                StubJunkScanner(category: .userCaches, items: [vivaldiCache, vivaldiNamedCache, item]),
                StubJunkScanner(category: .userLogs, items: [log])
            ]),
            cleanupService: CleanupService(remover: remover),
            trashEmptying: TrashEmptyingService(emptier: emptier),
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

    // MARK: Trash

    private func trashViewModel() async -> SystemJunkViewModel {
        let viewModel = makeViewModel(remover: remover, scanners: [
            StubJunkScanner(category: .trashBins, items: [homeBin, diskBin]),
            StubJunkScanner(category: .userLogs, items: [log])
        ])
        await viewModel.startScan().value
        return viewModel
    }

    @Test func leavesTheTrashUnselected() async {
        let viewModel = await trashViewModel()

        #expect(viewModel.foundSize == 3_507)
        #expect(viewModel.selectedItems == [log])
        #expect(!viewModel.emptiesTrash)
    }

    /// Finder empties every bin at once.
    @Test func selectsEveryTrashBinTogether() async {
        let viewModel = await trashViewModel()

        viewModel.toggle(diskBin)

        #expect(viewModel.binsToEmpty == [homeBin, diskBin])

        viewModel.toggle(homeBin)

        #expect(viewModel.binsToEmpty.isEmpty)
    }

    @Test func askingToEmptyTheTrashErasesNothing() async {
        let viewModel = await trashViewModel()
        viewModel.toggle(homeBin)

        viewModel.requestClean()
        viewModel.cancelClean()

        #expect(!viewModel.isConfirmingClean)
        #expect(emptier.emptyings.isEmpty)
        #expect(remover.removed.isEmpty)
    }

    @Test func aMixedSelectionAsksAboutBothAndEmptiesTheTrashBeforeMovingTheRest() async {
        let viewModel = await trashViewModel()
        viewModel.toggle(homeBin)

        viewModel.requestClean()

        #expect(viewModel.isConfirmingClean)
        #expect(viewModel.emptiesTrash)
        #expect(viewModel.binsToEmpty == [homeBin, diskBin])
        #expect(viewModel.itemsToMove == [log])
        #expect(emptier.emptyings.isEmpty)

        await viewModel.clean()?.value

        #expect(emptier.emptyings == [[]])
        #expect(remover.removed == [log.url])
        guard case .finished(let report) = viewModel.phase else {
            Issue.record("The cleanup didn't finish")
            return
        }
        #expect(report.emptiedTrash)
        #expect(report.removedCount == 1)
        #expect(report.freedBytes == 3_507)
    }

    @Test func cleaningWithoutTheTrashLeavesItAlone() async {
        let viewModel = await trashViewModel()
        viewModel.requestClean()

        await viewModel.clean()?.value

        #expect(emptier.emptyings.isEmpty)
        #expect(remover.removed == [log.url])
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
