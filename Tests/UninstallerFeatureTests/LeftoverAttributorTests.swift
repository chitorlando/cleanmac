import Foundation
import Testing
import UninstallerFeature

struct LeftoverAttributorTests {
    private let preferences = LeftoverLocation(
        url: URL(filePath: "/home/Library/Preferences"),
        kind: .preferences,
        rules: [.bundleID, .bundleIDPrefix]
    )

    private func app(_ path: String, _ bundleID: String) -> AppBundleInfo {
        let url = URL(filePath: path)
        return AppBundleInfo(url: url, bundleID: bundleID, name: url.deletingPathExtension().lastPathComponent)
    }

    private func candidate(_ name: String) -> LeftoverCandidate {
        LeftoverCandidate(url: preferences.url.appending(path: name), location: preferences)
    }

    private func names(of app: AppBundleInfo, in result: [AppBundleInfo.ID: [LeftoverCandidate]]) -> [String] {
        (result[app.id] ?? []).map(\.url.lastPathComponent).sorted()
    }

    @Test func longestPrefixWins() {
        let browser = app("/Applications/Vivaldi.app", "com.vivaldi.Vivaldi")
        let webApp = app("/Applications/Mail Web.app", "com.vivaldi.Vivaldi.app.abc")

        let result = LeftoverAttributor().attribute(
            [candidate("com.vivaldi.Vivaldi.app.abc.helper.plist"), candidate("com.vivaldi.Vivaldi.helper.plist")],
            to: [browser, webApp]
        )

        #expect(names(of: webApp, in: result) == ["com.vivaldi.Vivaldi.app.abc.helper.plist"])
        #expect(names(of: browser, in: result) == ["com.vivaldi.Vivaldi.helper.plist"])
    }

    @Test func exactMatchBeatsPrefix() {
        let chrome = app("/Applications/Google Chrome.app", "com.google.Chrome")
        let canary = app("/Applications/Google Chrome Canary.app", "com.google.Chrome.canary")

        let result = LeftoverAttributor().attribute(
            [candidate("com.google.Chrome.canary.plist"), candidate("com.google.Chrome.plist")],
            to: [chrome, canary]
        )

        #expect(names(of: canary, in: result) == ["com.google.Chrome.canary.plist"])
        #expect(names(of: chrome, in: result) == ["com.google.Chrome.plist"])
    }

    @Test func tiesAreSharedBetweenApps() {
        let copy = app("/Applications/Foo.app", "com.foo.app")
        let otherCopy = app("/Users/tester/Applications/Foo.app", "com.foo.app")

        let result = LeftoverAttributor().attribute([candidate("com.foo.app.plist")], to: [copy, otherCopy])

        #expect(names(of: copy, in: result) == ["com.foo.app.plist"])
        #expect(names(of: otherCopy, in: result) == ["com.foo.app.plist"])
    }

    @Test func ignoresItemsThatMatchNoApp() {
        let foo = app("/Applications/Foo.app", "com.foo.app")

        let result = LeftoverAttributor().attribute([candidate("com.bar.app.plist")], to: [foo])

        #expect(result.isEmpty)
    }
}
