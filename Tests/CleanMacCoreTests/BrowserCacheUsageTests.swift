import CleanMacCore
import Foundation
import Testing

struct BrowserCacheUsageTests {
    private let library = URL(filePath: "/home/Library")
    private let usage = BrowserCacheUsage(library: URL(filePath: "/home/Library"))

    private let vivaldi = RunningApp(url: URL(filePath: "/Applications/Vivaldi.app"), bundleID: "com.vivaldi.Vivaldi")
    private let chrome = RunningApp(url: URL(filePath: "/Applications/Google Chrome.app"), bundleID: "com.google.Chrome")
    private let canary = RunningApp(url: URL(filePath: "/Applications/Google Chrome Canary.app"), bundleID: "com.google.Chrome.canary")
    private let nightly = RunningApp(url: URL(filePath: "/Applications/Firefox Nightly.app"), bundleID: "org.mozilla.nightly")
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

    @Test func findsEveryOpenEdition() {
        #expect(apps(using: "Caches/Google", among: [chrome, canary, vivaldi]) == ["Google Chrome", "Google Chrome Canary"])
    }

    @Test func findsNothingWhenTheBrowserIsClosed() {
        #expect(apps(using: "Caches/Vivaldi", among: [chrome, mail]).isEmpty)
    }

    @Test func findsNothingForWhatNoBrowserUses() {
        let everything = [vivaldi, chrome, canary, nightly, mail]

        #expect(apps(using: "Caches/com.apple.mail", among: everything).isEmpty)
        #expect(apps(using: "Caches/GoogleUpdater", among: everything).isEmpty)
        #expect(apps(using: "Logs/Vivaldi", among: everything).isEmpty)
        #expect(usage.apps(using: URL(filePath: "/elsewhere/Caches/Vivaldi"), among: everything).isEmpty)
    }
}
