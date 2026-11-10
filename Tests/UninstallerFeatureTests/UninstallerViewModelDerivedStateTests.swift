import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

/// The visible apps, the selected items and the "select all" state are kept between reads,
/// so every test reads them before a change and checks that they follow it.
@MainActor
struct UninstallerViewModelDerivedStateTests {
    private let zoom = InstalledAppFixtures.app("Zoom", size: 900, leftovers: ["zoom-cache": 50])
    private let notes = InstalledAppFixtures.app("Notes", size: 10)

    private func loadedViewModel(runningApps: FakeRunningApps = FakeRunningApps()) async -> UninstallerViewModel {
        let apps = [zoom, notes]
        let viewModel = UninstallerViewModel(
            scanner: StubAppScanner(events: [.discovered(count: apps.count)] + apps.map { .analyzed($0) }),
            runningApps: runningApps,
            cleanupService: CleanupService(remover: RecordingRemover())
        )
        await viewModel.startLoading().value
        return viewModel
    }

    @Test func visibleAppsFollowTheQuery() async {
        let viewModel = await loadedViewModel()
        #expect(viewModel.visibleApps == [notes, zoom])

        viewModel.query.searchText = "zo"
        #expect(viewModel.visibleApps == [zoom])

        viewModel.query.searchText = ""
        viewModel.query.sortOrder = .size
        #expect(viewModel.visibleApps == [zoom, notes])
    }

    @Test func selectionTotalsFollowEveryToggle() async {
        let viewModel = await loadedViewModel()
        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)

        viewModel.toggle(zoom)
        #expect(viewModel.selectedSize == 950)
        #expect(viewModel.allSelectionState == .some)

        viewModel.toggle(notes.bundle)
        #expect(viewModel.selectedCount == 3)
        #expect(viewModel.allSelectionState == .all)

        viewModel.toggleAll()
        #expect(!viewModel.hasSelection)
        #expect(viewModel.allSelectionState == .none)
    }

    @Test func selectAllFollowsTheSearch() async {
        let viewModel = await loadedViewModel()
        viewModel.toggle(zoom)
        #expect(viewModel.allSelectionState == .some)

        viewModel.query.searchText = "zoom"

        #expect(viewModel.allSelectionState == .all)
    }

    @Test func selectionFollowsAnAppThatQuits() async {
        let viewModel = await loadedViewModel(runningApps: FakeRunningApps(running: [zoom.info.url]))
        viewModel.toggleAll()
        #expect(viewModel.selectedItems == [notes.bundle])
        #expect(viewModel.allSelectionState == .all)

        await viewModel.quit(zoom)
        #expect(viewModel.allSelectionState == .some)

        viewModel.toggle(zoom)
        #expect(viewModel.selectedItems == zoom.allItems + [notes.bundle])
    }

    @Test func reloadingStartsFromAnEmptyList() async {
        let viewModel = await loadedViewModel()
        viewModel.toggle(notes)
        #expect(viewModel.visibleApps.count == 2)
        #expect(viewModel.hasSelection)

        let reload = viewModel.startLoading()
        #expect(viewModel.visibleApps.isEmpty)
        #expect(!viewModel.hasSelection)

        await reload.value
        #expect(viewModel.visibleApps.count == 2)
    }
}
