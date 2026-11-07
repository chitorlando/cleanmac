import Foundation
import Testing
import UninstallerFeature

@MainActor
struct WorkspaceRunningAppsTests {
    private let notInstalled = FileManager.default.temporaryDirectory
        .appending(path: "\(UUID().uuidString).app")

    @Test func reportsStandardizedURLs() {
        let urls = WorkspaceRunningApps().runningAppURLs()
        #expect(urls.allSatisfy { $0 == $0.standardizedFileURL })
    }

    @Test func doesNotReportAnAppThatIsNotRunning() {
        #expect(!WorkspaceRunningApps().runningAppURLs().contains(notInstalled.standardizedFileURL))
    }

    @Test func quittingAnAppThatIsNotRunningSucceedsImmediately() async {
        let quitter = WorkspaceRunningApps(timeout: .zero)
        #expect(await quitter.quit(appAt: notInstalled))
    }
}
