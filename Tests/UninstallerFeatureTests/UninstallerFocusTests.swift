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
    /// An app outside the application folders, which a scan only finds when asked to.
    private let installer = InstalledAppFixtures.app("Installer", folder: "/home/Downloads")

    private func makeViewModel(finishes: Bool = true) -> UninstallerViewModel {
        let apps = [affinity, zoom, notes]
        return UninstallerViewModel(
            scanner: StubAppScanner(
                events: [.discovered(count: apps.count)] + apps.map { .analyzed($0) },
                finishes: finishes,
                appsElsewhere: [installer]
            ),
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
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
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.focusedAppID == notes.id)
    }

    @Test func loadsTheListAgainToFocusAnAppFromElsewhere() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value

        viewModel.focusApp(at: installer.info.url)
        #expect(viewModel.phase == .loading)
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.apps.contains(installer))
        #expect(viewModel.focusedAppID == installer.id)
    }

    @Test func loadsAnAppFromElsewhereStraightFromTheIntro() async {
        let viewModel = makeViewModel()

        viewModel.focusApp(at: installer.info.url)
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.focusedAppID == installer.id)
    }

    @Test func loadsAgainForAnAppFromElsewhereAskedForDuringALoad() async {
        let viewModel = makeViewModel()
        let loading = viewModel.startLoading()

        viewModel.focusApp(at: installer.info.url)
        await loading.value
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.focusedAppID == installer.id)
    }

    @Test func keepsAnAppFromElsewhereInLaterLoads() async {
        let viewModel = makeViewModel()
        viewModel.focusApp(at: installer.info.url)
        await waitUntilBrowsing(viewModel)

        await viewModel.startLoading().value

        #expect(viewModel.apps.contains(installer))
    }

    @Test func keepsTheListAndItsSelectionForAPathWithNoApp() async {
        let viewModel = makeViewModel()
        await viewModel.startLoading().value
        viewModel.toggle(zoom)

        viewModel.focusApp(at: URL(filePath: "/home/Downloads/Gone.app"))

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.selectedItems == [zoom.bundle])
    }

    @Test func loadsTheListFromTheIntroEvenForAPathWithNoApp() async {
        let viewModel = makeViewModel()

        viewModel.focusApp(at: URL(filePath: "/home/Downloads/Gone.app"))
        #expect(viewModel.phase == .loading)
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.focusedAppID == affinity.id)
    }

    @Test func cancellingTheLoadDropsTheRequest() async {
        let viewModel = makeViewModel()
        viewModel.focusApp(at: notes.info.url)
        viewModel.cancelLoading()

        await viewModel.startLoading().value

        #expect(viewModel.focusedAppID == affinity.id)
    }
}
