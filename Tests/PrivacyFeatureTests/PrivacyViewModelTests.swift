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
