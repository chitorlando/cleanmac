import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

/// Focusing an app that another feature, such as the disk map, sends to the uninstaller.
@MainActor
struct UninstallerFocusTests {
    private let affinity = InstalledAppFixtures.app("Affinity")
    private let zoom = InstalledAppFixtures.app("Zoom", size: 900)
    private let notes = InstalledAppFixtures.app("Notes", size: 10)

    private func makeViewModel(finishes: Bool = true) -> UninstallerViewModel {
        let apps = [affinity, zoom, notes]
        return UninstallerViewModel(
            scanner: StubAppScanner(events: [.discovered(count: apps.count)] + apps.map { .analyzed($0) }, finishes: finishes),
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
    }

    /// Waits until the loading started by `focusApp(at:)` ends.
    private func waitUntilBrowsing(_ viewModel: UninstallerViewModel) async {
        while viewModel.phase != .browsing {
            await Task.yield()
        }
    }

    @Test func focusesAnAppOfTheLoadedList() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value

        viewModel.focusApp(at: zoom.info.url)

        #expect(viewModel.focusedAppID == zoom.id)
    }

    @Test func loadsTheListFromTheIntroAndThenFocusesTheApp() async {
        let viewModel = makeViewModel()

        viewModel.focusApp(at: notes.info.url)
        #expect(viewModel.phase == .loading)
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.focusedAppID == notes.id)
    }

    @Test func focusesTheAppWhenALoadInProgressEnds() async {
        let viewModel = makeViewModel()
        let loading = viewModel.startLoading()

        viewModel.focusApp(at: notes.info.url)
        await loading.value

        #expect(viewModel.focusedAppID == notes.id)
    }

    @Test func matchesTheAppWhateverTheFormOfItsURL() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value

        viewModel.focusApp(at: URL(filePath: "/Applications/Utilities/../Zoom.app/"))

        #expect(viewModel.focusedAppID == zoom.id)
    }

    @Test func clearsASearchThatHidesTheApp() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value
        viewModel.query.searchText = "affinity"

        viewModel.focusApp(at: zoom.info.url)

        #expect(viewModel.query.searchText.isEmpty)
        #expect(viewModel.visibleApps.contains(zoom))
    }

    @Test func keepsASearchThatShowsTheApp() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value
        viewModel.query.searchText = "zo"

        viewModel.focusApp(at: zoom.info.url)

        #expect(viewModel.query.searchText == "zo")
    }

    @Test func leavesTheFocusAsItIsForUnknownApps() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value
        viewModel.focusedAppID = notes.id

        viewModel.focusApp(at: URL(filePath: "/Applications/Photoshop.app"))

        #expect(viewModel.focusedAppID == notes.id)
    }

    @Test func cancellingTheLoadDropsTheRequest() async {
        let viewModel = makeViewModel()
        viewModel.focusApp(at: notes.info.url)
        viewModel.cancelLoading()

        await viewModel.startLoading().value

        #expect(viewModel.focusedAppID == affinity.id)
    }
}
