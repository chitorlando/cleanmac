import CleanMacCore
import Foundation
import Testing

struct BrowserEditionTests {
    /// The names of the catalog's browsers that take an app with this bundle identifier as an edition.
    private func browsers(runningAs bundleID: String?) -> [String] {
        let app = RunningApp(url: URL(filePath: "/Applications/Some Browser.app"), bundleID: bundleID)
        return BrowserCatalog.browsers.filter { $0.isEdition(app) }.map(\.name)
    }

    @Test func takesABrowserAsAnEditionOfItself() {
        for browser in BrowserCatalog.browsers {
            #expect(browsers(runningAs: browser.bundleID) == [browser.name])
            #expect(browsers(runningAs: browser.bundleID.uppercased()) == [browser.name])
        }
    }

    /// Every edition of Firefox keeps the caches of its profiles in `~/Library/Caches/Firefox/Profiles`.
    @Test(arguments: ["org.mozilla.firefoxdeveloperedition", "org.mozilla.nightly"])
    func takesTheEditionsThatShareTheFoldersOfFirefox(bundleID: String) {
        #expect(browsers(runningAs: bundleID) == ["Firefox"])
    }

    /// Their cache folders in `~/Library/Caches` are named after them, so `cachesNamed` lists
    /// them under the browser whose bundle identifier they extend.
    @Test func takesTheEditionsNamedAfterABrowser() {
        let editions = [
            "com.google.Chrome.canary": "Google Chrome",
            "com.google.Chrome.beta": "Google Chrome",
            "com.microsoft.edgemac.Beta": "Microsoft Edge",
            "com.microsoft.edgemac.Dev": "Microsoft Edge",
            "com.brave.Browser.beta": "Brave",
            "com.brave.Browser.nightly": "Brave",
            "com.vivaldi.Vivaldi.snapshot": "Vivaldi"
        ]
        for (bundleID, browser) in editions {
            #expect(browsers(runningAs: bundleID) == [browser], "\(bundleID)")
        }
    }

    @Test(arguments: ["com.apple.SafariTechnologyPreview", "com.operasoftware.OperaGX", "org.mozilla.thunderbird", "com.apple.mail"])
    func leavesOutOtherApps(bundleID: String) {
        #expect(browsers(runningAs: bundleID).isEmpty)
    }

    @Test func leavesOutAppsWithoutABundleIdentifier() {
        #expect(browsers(runningAs: nil).isEmpty)
    }
}
