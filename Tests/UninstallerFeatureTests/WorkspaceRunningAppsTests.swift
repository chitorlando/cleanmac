import Foundation
import Testing
import UninstallerFeature

@MainActor
struct WorkspaceRunningAppsTests {
    private let notInstalled = FileManager.default.temporaryDirectory
        .appending(path: "\(UUID().uuidString).app")

    @Test func reportsStandardizedURLs() {
        let urls = WorkspaceRunningApps().runningApps().map(\.url)
        #expect(urls.allSatisfy { $0 == $0.standardizedFileURL })
    }

    @Test func doesNotReportAnAppThatIsNotRunning() {
        let urls = WorkspaceRunningApps().runningApps().map(\.url)
        #expect(!urls.contains(notInstalled.standardizedFileURL))
    }

    @Test func quittingAnAppThatIsNotRunningSucceedsImmediately() async {
        let quitter = WorkspaceRunningApps(timeout: .zero)
        #expect(await quitter.quit(appAt: notInstalled))
    }
}
