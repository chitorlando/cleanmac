import Foundation
import Testing
@testable import UninstallerFeature

struct RunningAppMatcherTests {
    private let zoom = InstalledAppFixtures.app("Zoom")
    private let notes = InstalledAppFixtures.app("Notes")
    /// A second copy of Zoom, with the same bundle identifier.
    private let zoomCopy = InstalledAppFixtures.app("Zoom", folder: "/home/Downloads")
    /// Where the system runs a quarantined app from.
    private let translocated = URL(filePath: "/private/var/folders/xy/T/AppTranslocation/1A2B/d/Zoom.app")

    private func running(_ app: InstalledApp) -> RunningApp {
        RunningApp(url: app.id.standardizedFileURL, bundleID: app.info.bundleID)
    }

    @Test func anAppRunningFromItsBundleIsRunning() {
        let matcher = RunningAppMatcher(runningApps: [running(zoom)], listedApps: [zoom, notes])

        #expect(matcher.isRunning(zoom))
        #expect(!matcher.isRunning(notes))
        #expect(matcher.instancesElsewhere(of: zoom).isEmpty)
    }

    @Test func anAppRunningFromAnotherPlaceIsRunning() {
        let instance = RunningApp(url: translocated, bundleID: "com.example.zoom")
        let matcher = RunningAppMatcher(runningApps: [instance], listedApps: [zoom, notes])

        #expect(matcher.isRunning(zoom))
        #expect(!matcher.isRunning(notes))
        #expect(matcher.instancesElsewhere(of: zoom) == [translocated])
    }

    @Test func everyCopyIsRunningWhenNothingTellsWhichOneIs() {
        let instance = RunningApp(url: translocated, bundleID: "com.example.zoom")
        let matcher = RunningAppMatcher(runningApps: [instance], listedApps: [zoom, zoomCopy])

        #expect(matcher.isRunning(zoom))
        #expect(matcher.isRunning(zoomCopy))
    }

    @Test func onlyTheCopyThatRunsFromItsBundleIsRunning() {
        let matcher = RunningAppMatcher(runningApps: [running(zoom)], listedApps: [zoom, zoomCopy])

        #expect(matcher.isRunning(zoom))
        #expect(!matcher.isRunning(zoomCopy))
    }

    @Test func bundleIdentifiersMatchWhateverTheirCase() {
        let instance = RunningApp(url: translocated, bundleID: "com.Example.ZOOM")
        let matcher = RunningAppMatcher(runningApps: [instance], listedApps: [zoom])

        #expect(matcher.isRunning(zoom))
    }

    @Test func aRunningAppWithoutBundleIdentifierOnlyMatchesByURL() {
        let unidentified = [RunningApp(url: translocated, bundleID: nil), RunningApp(url: notes.id, bundleID: nil)]
        let matcher = RunningAppMatcher(runningApps: unidentified, listedApps: [zoom, notes])

        #expect(!matcher.isRunning(zoom))
        #expect(matcher.isRunning(notes))
    }

    @Test func nothingIsRunningWithoutRunningApps() {
        let matcher = RunningAppMatcher(runningApps: [], listedApps: [zoom, notes])

        #expect(!matcher.isRunning(zoom))
        #expect(!matcher.isRunning(notes))
    }
}
