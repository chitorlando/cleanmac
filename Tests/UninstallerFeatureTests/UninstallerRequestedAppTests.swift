import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

/// Apps outside the application folders that another feature asks for more than once.
@MainActor
struct UninstallerRequestedAppTests {
    private let zoom = InstalledAppFixtures.app("Zoom")
    /// An app outside the application folders, which a scan only finds when asked to.
    private let installer = InstalledAppFixtures.app("Installer", folder: "/home/Downloads")

    private func makeViewModel(scanner: any InstalledAppScanning) -> UninstallerViewModel {
        UninstallerViewModel(
            scanner: scanner,
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
    }

    /// The load in progress leaves the first app out, and the second one, which it lists,
    /// must not make the uninstaller forget that the first was never analyzed.
    @Test func showsAnAppFromElsewhereAskedForBeforeAnotherAppDuringALoad() async {
        let viewModel = makeViewModel(
            scanner: StubAppScanner(
                events: [.discovered(count: 1), .analyzed(zoom)],
                appsElsewhere: [installer]
            )
        )
        let loading = viewModel.startLoading()
        viewModel.focusApp(at: installer.info.url)
        viewModel.focusApp(at: zoom.info.url)
        await loading.value
        await waitUntilBrowsing(viewModel)
        #expect(viewModel.apps.contains(installer))
        #expect(viewModel.focusedAppID == zoom.id)

        viewModel.focusApp(at: installer.info.url)

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.focusedAppID == installer.id)
    }

    @Test func doesNotLoadAgainForAPathWithNoAppAskedForDuringALoad() async {
        let viewModel = makeViewModel(scanner: StubAppScanner(events: [.discovered(count: 1), .analyzed(zoom)]))
        let loading = viewModel.startLoading()

        viewModel.focusApp(at: URL(filePath: "/home/Downloads/Gone.app"))
        await loading.value

        #expect(viewModel.phase == .browsing)
        #expect(viewModel.focusedAppID == zoom.id)
    }

    /// Such as an app in Downloads that was uninstalled and then downloaded again.
    @Test func showsAnAppFromElsewhereThatCameBackAfterALoadWithoutIt() async {
        let scanner = ChangingAppScanner(appsOnDisk: [installer])
        let viewModel = makeViewModel(scanner: scanner)
        viewModel.focusApp(at: installer.info.url)
        await waitUntilBrowsing(viewModel)
        scanner.remove(installer)
        await viewModel.startLoading().value
        scanner.add(installer)

        viewModel.focusApp(at: installer.info.url)
        await waitUntilBrowsing(viewModel)

        #expect(viewModel.apps.contains(installer))
        #expect(viewModel.focusedAppID == installer.id)
    }

    @Test func keepsTheListForAnAppFromElsewhereThatIsGone() async {
        let scanner = ChangingAppScanner(appsOnDisk: [installer])
        let viewModel = makeViewModel(scanner: scanner)
        viewModel.focusApp(at: installer.info.url)
        await waitUntilBrowsing(viewModel)
        scanner.remove(installer)
        await viewModel.startLoading().value

        viewModel.focusApp(at: installer.info.url)

        #expect(viewModel.phase == .browsing)
    }
}
