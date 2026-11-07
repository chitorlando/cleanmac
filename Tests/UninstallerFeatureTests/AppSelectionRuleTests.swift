import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

struct AppSelectionRuleTests {
    private let copy = InstalledAppFixtures.app("Affinity", leftovers: ["shared": 10, "own": 5])
    private let otherCopy = InstalledAppFixtures.app("Affinity", folder: "/home/Applications", leftovers: ["shared": 10])
    private let solo = InstalledAppFixtures.app("Solo", leftovers: ["solo-cache": 7])

    private var rule: AppSelectionRule {
        AppSelectionRule(shared: SharedLeftovers(apps: [copy, otherCopy, solo]))
    }

    private func item(_ app: InstalledApp, _ name: String) -> CleanableItem {
        app.allItems.first { $0.name == name }!
    }

    @Test func leftoversOfSeveralAppsAreShared() {
        let shared = SharedLeftovers(apps: [copy, otherCopy, solo])

        #expect(shared.contains(item(copy, "shared")))
        #expect(!shared.contains(item(copy, "own")))
        #expect(!shared.contains(item(solo, "solo-cache")))
        #expect(shared.sharedLeftovers(of: otherCopy).map(\.item.name) == ["shared"])
    }

    @Test func selectingAnAppSkipsSharedLeftovers() {
        var selection = ItemSelection()

        rule.toggle(copy, in: &selection)

        #expect(selection.contains(copy.bundle))
        #expect(selection.contains(item(copy, "own")))
        #expect(!selection.contains(item(copy, "shared")))
        #expect(rule.state(of: copy, in: selection) == .all)
    }

    @Test func selectingAllAppsSkipsSharedLeftovers() {
        var selection = ItemSelection()

        rule.toggle([copy, otherCopy, solo], in: &selection)

        #expect(!selection.contains(item(copy, "shared")))
        #expect(selection.contains(item(solo, "solo-cache")))
        #expect(rule.state(of: [copy, otherCopy, solo], in: selection) == .all)
    }

    @Test func sharedLeftoversCanBeSelectedByHand() {
        var selection = ItemSelection()

        selection.toggle(item(copy, "shared"))

        #expect(selection.contains(item(copy, "shared")))
        #expect(rule.state(of: otherCopy, in: selection) == .some)
    }

    @Test func togglingAFullySelectedAppClearsEverythingIncludingSharedItems() {
        var selection = ItemSelection()
        rule.toggle(copy, in: &selection)
        selection.toggle(item(copy, "shared"))

        rule.toggle(copy, in: &selection)

        #expect(selection.isEmpty)
    }

    @Test func togglingAllAppsWhenEverythingIsSelectedClearsThem() {
        var selection = ItemSelection()
        rule.toggle([copy, solo], in: &selection)

        rule.toggle([copy, solo], in: &selection)

        #expect(selection.isEmpty)
        #expect(rule.state(of: [copy, solo], in: selection) == .none)
    }

    @Test func partiallySelectedAppsReportSome() {
        var selection = ItemSelection()
        rule.toggle(solo, in: &selection)

        #expect(rule.state(of: [copy, solo], in: selection) == .some)
        #expect(rule.state(of: [], in: selection) == .none)
    }
}
