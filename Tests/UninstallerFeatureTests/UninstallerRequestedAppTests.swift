import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

/// Apps outside the application folders that another feature asks for more than once.
@MainActor
struct UninstallerRequestedAppTests {
    /// An app outside the application folders, which a scan only finds when asked to.
    private let installer = InstalledAppFixtures.app("Installer", folder: "/home/Downloads")

    private func makeViewModel(scanner: any InstalledAppScanning) -> UninstallerViewModel {
        UninstallerViewModel(
            scanner: scanner,
            runningApps: FakeRunningApps(),
            cleanupService: CleanupService(remover: RecordingRemover())
        )
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
