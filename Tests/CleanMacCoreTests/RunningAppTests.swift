import CleanMacCore
import Foundation
import Testing

@MainActor
struct RunningAppTests {
    /// Reports fixed apps and quits none.
    private struct StubRunningApps: RunningAppsProviding {
        let apps: [RunningApp]

        func runningApps() -> [RunningApp] { apps }

        func quit(appAt url: URL) async -> Bool { false }
    }

    private let vivaldi = RunningApp(url: URL(filePath: "/Applications/Vivaldi.app"), bundleID: "com.vivaldi.Vivaldi")
    private let helper = RunningApp(
        url: URL(filePath: "/Applications/Vivaldi.app/Contents/Frameworks/Vivaldi Framework.framework/Helpers/Vivaldi Helper.app"),
        bundleID: "com.vivaldi.Vivaldi.helper"
    )

    @Test func isNamedAfterItsBundle() {
        let canary = RunningApp(url: URL(filePath: "/private/var/folders/x/Google Chrome Canary.app"), bundleID: nil)

        #expect(vivaldi.name == "Vivaldi")
        #expect(canary.name == "Google Chrome Canary")
    }

    @Test func tellsTheHelpersInsideAnotherApp() {
        #expect(helper.isHelper)
        #expect(!vivaldi.isHelper)
    }

    @Test func leavesTheHelpersOutOfTheOpenApps() {
        #expect(StubRunningApps(apps: [helper, vivaldi]).openApps() == [vivaldi])
    }
}
