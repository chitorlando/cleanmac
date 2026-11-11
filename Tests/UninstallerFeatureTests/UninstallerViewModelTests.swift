import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

@MainActor
struct UninstallerViewModelTests {
    private let affinity = InstalledAppFixtures.app("Affinity", size: 400, leftovers: ["affinity-shared": 30, "affinity-own": 20])
    private let affinityCopy = InstalledAppFixtures.app("Affinity", folder: "/home/Applications", size: 400, leftovers: ["affinity-shared": 30])
    private let zoom = InstalledAppFixtures.app("Zoom", size: 900, leftovers: ["zoom-cache": 50])
    private let notes = InstalledAppFixtures.app("Notes", size: 10)

    /// Where the system runs a quarantined copy of Zoom from, instead of from its bundle.
    private let translocatedZoom = URL(filePath: "/private/var/folders/xy/T/AppTranslocation/1A2B/d/Zoom.app")

    private let remover = RecordingRemover()

    private func makeViewModel(
        apps: [InstalledApp]? = nil,
        events: [AppScanEvent]? = nil,
        finishes: Bool = true,
        runningApps: FakeRunningApps = FakeRunningApps()
    ) -> UninstallerViewModel {
        let apps = apps ?? [affinity, affinityCopy, zoom, notes]
        let scanner = StubAppScanner(
            events: events ?? [.discovered(count: apps.count)] + apps.map { .analyzed($0) },
            finishes: finishes
        )
        return UninstallerViewModel(
            scanner: scanner,
            runningApps: runningApps,
            cleanupService: CleanupService(remover: remover)
        )
    }

    private func loadedViewModel(runningApps: FakeRunningApps = FakeRunningApps()) async -> UninstallerViewModel {
        let viewModel = makeViewModel(runningApps: runningApps)
        await viewModel.startLoading().value
        return viewModel
    }

    private func item(_ app: InstalledApp, _ name: String) -> CleanableItem {
        app.allItems.first { $0.name == name }!
    }

    // MARK: Phases and progress

    @Test func startsOnTheIntro() {
        let viewModel = makeViewModel()

        #expect(viewModel.phase == .intro)
        #expect(viewModel.loadProgress == 0)
    }

    @Test func loadsEveryAppAndStartsBrowsing() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.apps.count == 4)
        #expect(viewModel.discoveredCount == 4)
        #expect(viewModel.analyzedCount == 4)
        #expect(viewModel.loadProgress == 1)
        #expect(!viewModel.hasSelection)
    }

    @Test func reportsProgressAsAnalyzedOverDiscovered() async {
        let viewModel = makeViewModel(events: [.discovered(count: 4), .analyzed(zoom), .analyzed(notes)])

        await viewModel.startLoading().value

        #expect(viewModel.loadProgress == 0.5)
    }

    @Test func cancellingTheLoadReturnsToTheIntro() async {
        let viewModel = makeViewModel(events: [.discovered(count: 4)], finishes: false)

        let task = viewModel.startLoading()
        #expect(viewModel.phase == .loading)
        viewModel.cancelLoading()
        await task.value

        #expect(viewModel.phase == .intro)
    }

    @Test func focusesTheFirstVisibleAppAfterLoading() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.focusedApp == viewModel.visibleApps.first)
        #expect(viewModel.focusedApp?.info.name == "Affinity")
    }

    // MARK: Search and sort

    @Test func filtersAndSortsTheVisibleApps() async {
        let viewModel = await loadedViewModel()

        viewModel.query.searchText = "AFFI"
        #expect(viewModel.visibleApps.map(\.id) == [affinity.id, affinityCopy.id])

        viewModel.query = AppListQuery(sortOrder: .size)
        #expect(viewModel.visibleApps.first == zoom)
    }

    // MARK: Shared leftovers

    @Test func exposesSharedLeftovers() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.isShared(item(affinity, "affinity-shared")))
        #expect(!viewModel.isShared(item(affinity, "affinity-own")))
    }

    @Test func selectingAnAppLeavesSharedLeftoversUnmarked() async {
        let viewModel = await loadedViewModel()

        viewModel.toggle(affinity)

        #expect(viewModel.selectionState(of: affinity) == .all)
        #expect(viewModel.isSelected(affinity.bundle))
        #expect(viewModel.isSelected(item(affinity, "affinity-own")))
        #expect(!viewModel.isSelected(item(affinity, "affinity-shared")))
        #expect(viewModel.selectedCount == 2)
        #expect(viewModel.selectedSize == 420)
        #expect(viewModel.selectedAppCount == 1)
    }

    @Test func selectingAllLeavesSharedLeftoversUnmarked() async {
        let viewModel = await loadedViewModel()

        viewModel.toggleAll()

        #expect(viewModel.allSelectionState == .all)
        #expect(!viewModel.isSelected(item(affinity, "affinity-shared")))
        #expect(viewModel.selectedAppCount == 4)
    }

    @Test func sharedLeftoversCanBeMarkedByHand() async {
        let viewModel = await loadedViewModel()

        viewModel.toggle(item(affinity, "affinity-shared"))

        #expect(viewModel.isSelected(item(affinity, "affinity-shared")))
        #expect(viewModel.selectionState(of: affinityCopy) == .some)
    }

    @Test func selectAllOnlyAffectsVisibleApps() async {
        let viewModel = await loadedViewModel()
        viewModel.query.searchText = "zoom"

        viewModel.toggleAll()

        #expect(viewModel.selectedItems == zoom.allItems)
    }

    // MARK: Running apps

    @Test func itemsOfRunningAppsCannotBeSelected() async {
        let viewModel = await loadedViewModel(runningApps: FakeRunningApps(running: [zoom.info.url]))

        viewModel.toggle(zoom)
        viewModel.toggle(item(zoom, "zoom-cache"))
        viewModel.toggleAll()

        #expect(viewModel.isRunning(zoom))
        #expect(!viewModel.canSelect(zoom.bundle))
        #expect(viewModel.selectionState(of: zoom) == .none)
        #expect(!viewModel.selectedItems.contains(zoom.bundle))
    }

    @Test func appsThatStartRunningAreDeselectedBeforeUninstalling() async {
        let runningApps = FakeRunningApps()
        let viewModel = await loadedViewModel(runningApps: runningApps)
        viewModel.toggle(zoom)
        viewModel.toggle(notes)

        runningApps.running = [zoom.info.url]
        await viewModel.uninstall()?.value

        #expect(remover.removed == [notes.bundle.url])
        #expect(!viewModel.selection.contains(zoom.bundle))
    }

    @Test func quittingAnAppMakesItSelectable() async {
        let runningApps = FakeRunningApps(running: [zoom.info.url])
        let viewModel = await loadedViewModel(runningApps: runningApps)

        let didQuit = await viewModel.quit(zoom)
        viewModel.toggle(zoom)

        #expect(didQuit)
        #expect(runningApps.quitRequests == [zoom.info.url])
        #expect(!viewModel.isRunning(zoom))
        #expect(!viewModel.isQuitting(zoom))
        #expect(viewModel.selectionState(of: zoom) == .all)
    }

    @Test func anAppTheSystemRunsFromAnotherPlaceCannotBeSelected() async {
        let runningApps = FakeRunningApps()
        runningApps.runningElsewhere = [RunningApp(url: translocatedZoom, bundleID: "com.example.zoom")]
        let viewModel = await loadedViewModel(runningApps: runningApps)

        viewModel.toggle(zoom)
        viewModel.toggle(item(zoom, "zoom-cache"))
        viewModel.toggleAll()

        #expect(viewModel.isRunning(zoom))
        #expect(!viewModel.isRunning(notes))
        #expect(!viewModel.canSelect(zoom.bundle))
        #expect(!viewModel.selectedItems.contains(zoom.bundle))
        #expect(!viewModel.selectedItems.contains(item(zoom, "zoom-cache")))
    }

    @Test func quittingAnAppTheSystemRunsFromAnotherPlaceMakesItSelectable() async {
        let runningApps = FakeRunningApps()
        runningApps.runningElsewhere = [RunningApp(url: translocatedZoom, bundleID: "com.example.zoom")]
        let viewModel = await loadedViewModel(runningApps: runningApps)

        let didQuit = await viewModel.quit(zoom)
        viewModel.toggle(zoom)

        #expect(didQuit)
        #expect(runningApps.quitRequests == [zoom.info.url, translocatedZoom])
        #expect(!viewModel.isRunning(zoom))
        #expect(viewModel.selectionState(of: zoom) == .all)
    }

    @Test func anAppThatRefusesToQuitStaysLocked() async {
        let runningApps = FakeRunningApps(running: [zoom.info.url])
        runningApps.quitSucceeds = false
        let viewModel = await loadedViewModel(runningApps: runningApps)

        let didQuit = await viewModel.quit(zoom)

        #expect(!didQuit)
        #expect(viewModel.isRunning(zoom))
    }

    // MARK: Uninstalling

    @Test func uninstallsTheSelectedItemsOnce() async {
        let viewModel = await loadedViewModel()
        viewModel.toggle(affinity)
        viewModel.toggle(affinityCopy)
        viewModel.toggle(item(affinity, "affinity-shared"))

        await viewModel.uninstall()?.value

        let expected = [affinity.bundle, item(affinity, "affinity-own"), item(affinity, "affinity-shared"), affinityCopy.bundle]
        #expect(Set(remover.removed) == Set(expected.map(\.url)))
        #expect(remover.removed.count == expected.count)
        guard case .finished(let report) = viewModel.phase else {
            Issue.record("Expected the finished phase, got \(viewModel.phase)")
            return
        }
        #expect(report.removedCount == 4)
        #expect(report.freedBytes == 850)
    }

    @Test func doesNothingWithoutASelection() async {
        let viewModel = await loadedViewModel()

        #expect(viewModel.uninstall() == nil)
        #expect(viewModel.phase == .browsing)
        #expect(remover.removed.isEmpty)
    }

    @Test func restartingDuringAnUninstallIgnoresItsResult() async {
        let gated = GatedRemover()
        let viewModel = UninstallerViewModel(
            scanner: StubAppScanner(events: [.discovered(count: 1), .analyzed(notes)]),
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: gated)
        )
        await viewModel.startLoading().value
        viewModel.toggle(notes)

        let uninstall = viewModel.uninstall()
        await gated.waitUntilRemoving()
        await viewModel.startLoading().value
        await gated.open()
        await uninstall?.value

        #expect(viewModel.phase == .browsing)
    }

    @Test func doneLoadsTheListAgain() async {
        let viewModel = await loadedViewModel()
        viewModel.toggle(notes)
        await viewModel.uninstall()?.value

        await viewModel.done().value

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.apps.count == 4)
        #expect(!viewModel.hasSelection)
    }
}
