import CleanMacCore
import Foundation
import Testing
@testable import UninstallerFeature

struct AppSelectionMemoTests {
    private let copy = InstalledAppFixtures.app("Affinity", leftovers: ["shared": 10, "own": 5])
    private let otherCopy = InstalledAppFixtures.app("Affinity", folder: "/home/Applications", leftovers: ["shared": 10])
    private let solo = InstalledAppFixtures.app("Solo", leftovers: ["solo-cache": 7])

    private var apps: [InstalledApp] { [copy, otherCopy, solo] }

    private func item(_ app: InstalledApp, _ name: String) -> CleanableItem {
        app.allItems.first { $0.name == name }!
    }

    /// The apps the memo asks about when it is asked for the state of every app.
    private func appsAsked(by memo: inout AppSelectionMemo) -> [InstalledApp] {
        var asked: [InstalledApp] = []
        _ = memo.states(of: apps) { app in
            asked.append(app)
            return .none
        }
        return asked
    }

    // MARK: States

    @Test func asksForTheStateOfEachAppOnce() {
        var memo = AppSelectionMemo(apps: apps)

        let first = memo.states(of: apps) { _ in .all }
        let second = memo.states(of: apps) { _ in .none }

        #expect(first == [.all, .all, .all])
        #expect(second == [.all, .all, .all])
    }

    @Test func asksAgainOnlyAboutTheAppThatListsAChangedItem() {
        var memo = AppSelectionMemo(apps: apps)
        _ = memo.states(of: apps) { _ in .none }

        memo.forget(appsListing: [item(solo, "solo-cache")])
        let states = memo.states(of: apps) { _ in .some }

        #expect(states == [.none, .none, .some])
    }

    @Test func asksAgainAboutEveryAppThatListsASharedItem() {
        var memo = AppSelectionMemo(apps: apps)
        _ = appsAsked(by: &memo)

        memo.forget(appsListing: [item(copy, "shared")])
        let asked = appsAsked(by: &memo)

        #expect(asked == [copy, otherCopy])
    }

    @Test func asksAgainAboutEveryAppAfterForgettingEverything() {
        var memo = AppSelectionMemo(apps: apps)
        _ = appsAsked(by: &memo)

        memo.forgetEverything()
        let asked = appsAsked(by: &memo)

        #expect(asked == apps)
    }

    @Test func forgetsNothingForAnItemNoAppLists() {
        var memo = AppSelectionMemo(apps: apps)
        _ = appsAsked(by: &memo)

        memo.forget(appsListing: [CleanableItem(url: URL(filePath: "/tmp/elsewhere"), size: 1)])
        let asked = appsAsked(by: &memo)

        #expect(asked.isEmpty)
    }

    @Test func keepsTheOrderOfTheAppsItIsAskedAbout() {
        var memo = AppSelectionMemo(apps: apps)

        let states = memo.states(of: [solo, copy]) { $0 == solo ? .all : .none }

        #expect(states == [.all, .none])
    }

    @Test func computesTheStateOfAnAppThatIsNotInTheList() {
        var memo = AppSelectionMemo(apps: [copy])

        let states = memo.states(of: [solo]) { _ in .some }

        #expect(states == [.some])
    }

    // MARK: Selected items

    @Test func listsSelectedItemsInOrderAndOnceEach() {
        var memo = AppSelectionMemo(apps: apps)

        let items = memo.selectedItems { $0.name != "own" }

        #expect(items == [copy.bundle, item(copy, "shared"), otherCopy.bundle, solo.bundle, item(solo, "solo-cache")])
    }

    @Test func asksAboutEachItemOnceUntilItChanges() {
        var memo = AppSelectionMemo(apps: apps)
        let soloBundle = solo.bundle
        var asked: [CleanableItem] = []
        _ = memo.selectedItems { _ in true }

        let unchanged = memo.selectedItems { item in
            asked.append(item)
            return false
        }
        #expect(unchanged.count == 6)
        #expect(asked.isEmpty)

        memo.forget(appsListing: [soloBundle])
        let changed = memo.selectedItems { item in
            asked.append(item)
            return item != soloBundle
        }
        #expect(changed == copy.allItems + [otherCopy.bundle, item(solo, "solo-cache")])
        #expect(asked == solo.allItems)
    }

    @Test func anEmptyListHasNothingSelected() {
        var memo = AppSelectionMemo(apps: [])

        let items = memo.selectedItems { _ in true }
        let states = memo.states(of: []) { _ in .all }

        #expect(items.isEmpty)
        #expect(states.isEmpty)
    }
}
