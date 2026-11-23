import CleanMacCore
import Foundation
import PrivacyFeature
import Testing

@MainActor
struct PrivacyViewModelTests {
    private let safari = browserCaches("Safari", bundleID: "com.apple.Safari", items: ["a": 100])
    private let chrome = browserCaches("Google Chrome", bundleID: "com.google.Chrome", items: ["b": 300, "c": 200])
    private let remover = RecordingRemover()
    private let runningApps = FakeRunningApps()

    /// Chrome as the system reports it while open, from wherever it runs.
    private var openChrome: RunningApp {
        RunningApp(url: URL(filePath: "/private/var/folders/x/Google Chrome.app"), bundleID: "com.google.Chrome")
    }

    private func scannedViewModel() async -> PrivacyViewModel {
        let viewModel = PrivacyViewModel(
            scanner: StubBrowserCacheScanner(results: [safari, chrome]),
            runningApps: runningApps,
            cleanupService: CleanupService(remover: remover)
        )
        await viewModel.startScan().value
        return viewModel
    }

    @Test func listsTheBrowsersLargestFirstWithEverythingSelected() async {
        let viewModel = await scannedViewModel()

        #expect(viewModel.phase == .review)
        #expect(viewModel.results.map(\.name) == ["Google Chrome", "Safari"])
        #expect(viewModel.selectedSize == 600)
        #expect(viewModel.foundSize == 600)
    }

    /// What service workers stored is listed, but only the user selects it, item by item.
    @Test func leavesSiteDataUnselectedUntilTheUserSelectsIt() async throws {
        let edge = browserCaches("Microsoft Edge", bundleID: "com.microsoft.edgemac", items: ["Cache": 50], siteData: ["ScriptCache": 900])
        let viewModel = PrivacyViewModel(
            scanner: StubBrowserCacheScanner(results: [edge]),
            runningApps: runningApps,
            cleanupService: CleanupService(remover: remover)
        )
        await viewModel.startScan().value
        let siteData = try #require(edge.items.first(where: { edge.holdsSiteData($0) }))

        #expect(viewModel.foundSize == 950)
        #expect(viewModel.selectedItems == edge.cacheItems)
        #expect(viewModel.selectionState(of: edge) == .some)

        viewModel.toggle(edge)
        #expect(viewModel.selectedItems.isEmpty)
        viewModel.toggle(edge)
        #expect(viewModel.selectedItems == edge.cacheItems)

        viewModel.toggle(siteData, of: edge)
        #expect(viewModel.selectedSize == 950)
        viewModel.toggle(edge)
        #expect(viewModel.selectedItems.isEmpty)
    }

    @Test func locksTheCachesOfAnOpenBrowser() async throws {
        runningApps.running = [openChrome]
        let viewModel = await scannedViewModel()
        let item = try #require(chrome.items.first)

        viewModel.toggle(chrome)
        viewModel.toggle(item, of: chrome)

        #expect(viewModel.isRunning(chrome))
        #expect(!viewModel.isSelected(item, of: chrome))
        #expect(viewModel.selectionState(of: chrome) == .none)
        #expect(viewModel.selectedItems == safari.items)
    }

    @Test func recognizesBrowsersByBundleIDIgnoringCase() async {
        runningApps.running = [RunningApp(url: URL(filePath: "/Applications/Safari.app"), bundleID: "COM.APPLE.SAFARI")]

        #expect(await scannedViewModel().isRunning(safari))
    }

    @Test func quitsAnOpenBrowserWhereItRunsAndThenSelectsItsCaches() async {
        runningApps.running = [openChrome]
        let viewModel = await scannedViewModel()

        let didQuit = await viewModel.quit(chrome)

        #expect(didQuit)
        #expect(runningApps.quitRequests == [openChrome.url])
        #expect(!viewModel.isRunning(chrome))
        #expect(viewModel.selectionState(of: chrome) == .all)
    }

    @Test func locksTheCachesWhileAnotherEditionIsOpenAndQuitsIt() async {
        let canary = RunningApp(url: URL(filePath: "/Applications/Google Chrome Canary.app"), bundleID: "com.google.Chrome.canary")
        runningApps.running = [canary]
        let viewModel = await scannedViewModel()

        #expect(viewModel.isRunning(chrome))
        #expect(viewModel.openApps(of: chrome).map(\.name) == ["Google Chrome Canary"])
        #expect(viewModel.selectedItems == safari.items)

        #expect(await viewModel.quit(chrome))
        #expect(runningApps.quitRequests == [canary.url])
        #expect(viewModel.selectionState(of: chrome) == .all)
    }

    /// A helper runs inside the browser's bundle and closes with it, so it's never asked to quit.
    @Test func leavesTheHelpersOfABrowserAlone() async {
        let helper = RunningApp(
            url: URL(filePath: "/Applications/Google Chrome.app/Contents/Frameworks/Helpers/Google Chrome Helper.app"),
            bundleID: "com.google.Chrome.helper"
        )
        runningApps.running = [helper]
        let viewModel = await scannedViewModel()

        #expect(!viewModel.isRunning(chrome))

        runningApps.running = [openChrome, helper]
        viewModel.refreshRunningBrowsers()
        await viewModel.quit(chrome)

        #expect(runningApps.quitRequests == [openChrome.url])
    }

    @Test func keepsTheCachesLockedWhenTheBrowserDoesNotQuit() async {
        runningApps.running = [openChrome]
        runningApps.quitSucceeds = false
        let viewModel = await scannedViewModel()

        #expect(await !viewModel.quit(chrome))
        #expect(viewModel.isRunning(chrome))
        #expect(viewModel.selectedItems == safari.items)
    }

    @Test func leavesOutABrowserOpenedBeforeCleaning() async {
        let viewModel = await scannedViewModel()
        runningApps.running = [openChrome]

        await viewModel.clean()?.value

        #expect(remover.removed == safari.items.map(\.url))
    }

    @Test func movesTheSelectionToTheTrash() async throws {
        let viewModel = await scannedViewModel()
        viewModel.toggle(chrome)

        await viewModel.clean()?.value

        #expect(remover.removed == safari.items.map(\.url))
        guard case .finished(let report) = viewModel.phase else {
            Issue.record("Expected the finished phase, got \(viewModel.phase)")
            return
        }
        #expect(report.removedCount == 1)
    }

    @Test func cleansNothingWithoutASelection() async {
        let viewModel = await scannedViewModel()
        viewModel.toggle(chrome)
        viewModel.toggle(safari)

        #expect(viewModel.clean() == nil)
        #expect(viewModel.phase == .review)
    }

    @Test func goesBackToTheIntroductionWhenDone() async {
        let viewModel = await scannedViewModel()
        await viewModel.clean()?.value

        viewModel.done()

        #expect(viewModel.phase == .intro)
        #expect(viewModel.results.isEmpty)
    }
}
