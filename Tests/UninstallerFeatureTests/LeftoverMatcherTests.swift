import Foundation
import Testing
import UninstallerFeature

struct LeftoverMatcherTests {
    private let app = AppBundleInfo(
        url: URL(filePath: "/Applications/Foo.app"),
        bundleID: "com.foo.App",
        name: "Foo",
        alternateNames: ["Foo Studio"]
    )
    private let allRules: [MatchRule] = [.bundleID, .bundleIDPrefix, .groupContainer, .appName]

    private func rule(_ fileName: String, rules: [MatchRule]? = nil, app: AppBundleInfo? = nil) -> MatchRule? {
        LeftoverMatcher.strength(of: fileName, for: app ?? self.app, rules: rules ?? allRules)?.rule
    }

    @Test func matchesExactBundleID() {
        #expect(rule("com.foo.App") == .bundleID)
    }

    @Test func matchesBundleIDPrefixOnlyAtADotBoundary() {
        #expect(rule("com.foo.App.helper") == .bundleIDPrefix)
        #expect(rule("com.foo.Application") == nil)
    }

    @Test func matchesGroupContainers() {
        #expect(rule("group.com.foo.App") == .groupContainer)
        #expect(rule("ABCDE12345.com.foo.App") == .groupContainer)
    }

    @Test func matchesAppNameAndAlternateNames() {
        #expect(rule("Foo") == .appName)
        #expect(rule("Foo Studio") == .appName)
        #expect(rule("Foobar") == nil)
    }

    @Test func ignoresCase() {
        #expect(rule("COM.FOO.APP") == .bundleID)
        #expect(rule("foo studio") == .appName)
    }

    @Test func stripsKnownExtensions() {
        #expect(rule("com.foo.App.plist") == .bundleID)
        #expect(rule("com.foo.App.savedState") == .bundleID)
        #expect(rule("com.foo.App.binarycookies") == .bundleID)
        #expect(rule("com.foo.App.ABC-123.plist") == .bundleIDPrefix)
        #expect(rule("Foo.PLIST") == .appName)
    }

    @Test func keepsUnknownExtensions() {
        #expect(rule("Foo.log") == nil)
    }

    @Test func ignoresAppNamesShorterThanThreeCharacters() {
        let shortApp = AppBundleInfo(
            url: URL(filePath: "/Applications/Go.app"),
            bundleID: "com.example.go",
            name: "Go",
            alternateNames: ["X"]
        )
        #expect(rule("Go", app: shortApp) == nil)
        #expect(rule("X", app: shortApp) == nil)
    }

    @Test func onlyAppliesTheGivenRules() {
        #expect(rule("Foo", rules: [.bundleID, .bundleIDPrefix]) == nil)
        #expect(rule("com.foo.App.helper", rules: [.bundleID]) == nil)
    }

    @Test func picksTheStrongestMatchingRule() {
        let named = AppBundleInfo(url: URL(filePath: "/Applications/x.app"), bundleID: "com.x.app", name: "com.x.app")
        #expect(rule("com.x.app", app: named) == .bundleID)
    }

    @Test func ranksRulesAndThenSpecificity() {
        let exact = MatchStrength(rule: .bundleID, specificity: 5)
        let group = MatchStrength(rule: .groupContainer, specificity: 50)
        let name = MatchStrength(rule: .appName, specificity: 50)
        let shortPrefix = MatchStrength(rule: .bundleIDPrefix, specificity: 10)
        let longPrefix = MatchStrength(rule: .bundleIDPrefix, specificity: 20)

        #expect([longPrefix, name, exact, shortPrefix, group].sorted() == [shortPrefix, longPrefix, name, group, exact])
    }
}
