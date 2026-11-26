import CleanMacCore
import Foundation
import Testing

struct BrowserCacheUsageTests {
    private let library = URL(filePath: "/home/Library")
    private let usage = BrowserCacheUsage(library: URL(filePath: "/home/Library"))

    private let vivaldi = RunningApp(url: URL(filePath: "/Applications/Vivaldi.app"), bundleID: "com.vivaldi.Vivaldi")
    private let chrome = RunningApp(url: URL(filePath: "/Applications/Google Chrome.app"), bundleID: "com.google.Chrome")
    private let canary = RunningApp(url: URL(filePath: "/Applications/Google Chrome Canary.app"), bundleID: "com.google.Chrome.canary")
    private let firefox = RunningApp(url: URL(filePath: "/Applications/Firefox.app"), bundleID: "org.mozilla.firefox")
    private let nightly = RunningApp(url: URL(filePath: "/Applications/Firefox Nightly.app"), bundleID: "org.mozilla.nightly")
    private let edge = RunningApp(url: URL(filePath: "/Applications/Microsoft Edge.app"), bundleID: "com.microsoft.edgemac")
    private let edgeBeta = RunningApp(url: URL(filePath: "/Applications/Microsoft Edge Beta.app"), bundleID: "com.microsoft.edgemac.Beta")
    private let mail = RunningApp(url: URL(filePath: "/System/Applications/Mail.app"), bundleID: "com.apple.mail")

    /// The names of the open apps that may be using an item of the Library.
    private func apps(using path: String, among openApps: [RunningApp]) -> [String] {
        usage.apps(using: library.appending(path: path), among: openApps).map(\.name)
    }

    @Test func findsTheOpenBrowserThatUsesAFolderOfTheCaches() {
        #expect(apps(using: "Caches/Vivaldi", among: [mail, vivaldi, chrome]) == ["Vivaldi"])
        #expect(apps(using: "Caches/vivaldi", among: [vivaldi]) == ["Vivaldi"])
    }

    /// System Junk lists `~/Library/Caches/Google` whole, with the caches of Chrome inside.
    @Test func findsTheBrowserThatKeepsCachesInsideTheItem() {
        #expect(apps(using: "Caches/Google", among: [chrome]) == ["Google Chrome"])
        #expect(apps(using: "Caches/Firefox", among: [nightly]) == ["Firefox Nightly"])
    }

    @Test func findsTheBrowserThatKeepsTheItemInsideACacheFolder() {
        #expect(apps(using: "Caches/Google/Chrome/Default/Cache", among: [chrome]) == ["Google Chrome"])
        #expect(apps(using: "Application Support/Google/Chrome/Default/Code Cache", among: [chrome]) == ["Google Chrome"])
    }

    @Test func findsTheBrowserACacheIsNamedAfter() {
        #expect(apps(using: "Caches/com.vivaldi.Vivaldi", among: [vivaldi]) == ["Vivaldi"])
        #expect(apps(using: "Caches/com.google.Chrome.canary", among: [canary]) == ["Google Chrome Canary"])
    }

    /// Editions the catalog doesn't list keep their caches next to the browser's, after its name.
    /// Any open edition locks them, as Privacy locks a whole browser.
    @Test func findsTheOpenBrowserWhoseEditionKeepsCachesNextToItsOwn() {
        #expect(apps(using: "Caches/Microsoft Edge Beta", among: [mail, edge]) == ["Microsoft Edge"])
        #expect(apps(using: "Caches/Microsoft Edge Beta", among: [edgeBeta]) == ["Microsoft Edge Beta"])
        #expect(apps(using: "Caches/Vivaldi Snapshot", among: [vivaldi]) == ["Vivaldi"])
        #expect(apps(using: "Caches/Microsoft Edge Beta", among: [chrome, mail]).isEmpty)
    }

    @Test func findsNothingForAFolderThatOnlyStartsLikeABrowsers() {
        #expect(apps(using: "Caches/Microsoft Teams", among: [edge]).isEmpty)
        #expect(apps(using: "Caches/Microsoft Edge Updater", among: [edge]).isEmpty)
        #expect(apps(using: "Caches/Vivaldi Tools", among: [vivaldi]).isEmpty)
        #expect(apps(using: "Caches/VivaldiBeta", among: [vivaldi]).isEmpty)
    }

    /// Firefox keeps the updates it downloads in `~/Library/Caches/Mozilla`.
    @Test func findsTheOpenBrowserThatUsesASharedFolder() {
        #expect(apps(using: "Caches/Mozilla", among: [mail, firefox]) == ["Firefox"])
        #expect(apps(using: "Caches/Mozilla/updates", among: [nightly]) == ["Firefox Nightly"])
    }

    @Test func findsNothingInASharedFolderWhenTheBrowserIsClosed() {
        #expect(apps(using: "Caches/Mozilla", among: [chrome, vivaldi, mail]).isEmpty)
    }

    @Test func findsEveryOpenEdition() {
        #expect(apps(using: "Caches/Google", among: [chrome, canary, vivaldi]) == ["Google Chrome", "Google Chrome Canary"])
    }

    @Test func findsNothingWhenTheBrowserIsClosed() {
        #expect(apps(using: "Caches/Vivaldi", among: [chrome, mail]).isEmpty)
    }

    @Test func findsNothingForWhatNoBrowserUses() {
        let everything = [vivaldi, chrome, canary, firefox, nightly, mail]

        #expect(apps(using: "Caches/com.apple.mail", among: everything).isEmpty)
        #expect(apps(using: "Caches/GoogleUpdater", among: everything).isEmpty)
        #expect(apps(using: "Logs/Vivaldi", among: everything).isEmpty)
        #expect(usage.apps(using: URL(filePath: "/elsewhere/Caches/Vivaldi"), among: everything).isEmpty)
    }
}
