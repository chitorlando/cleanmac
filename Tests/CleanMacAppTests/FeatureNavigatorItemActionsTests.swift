@testable import CleanMacApp
import CleanMacUI
import Foundation
import Testing

@MainActor
struct FeatureNavigatorItemActionsTests {
    @Test func gathersTheActionsOfEveryFeatureInTheirOrder() {
        let modules: [any FeatureModule] = [
            FakeFeature("disk-map", in: .files),
            FakeFeature("duplicates", in: .files, offering: [.folder]),
            FakeFeature("uninstaller", in: .applications, offering: [.app])
        ]
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        #expect(navigator.itemActions.map(\.featureID) == ["duplicates", "uninstaller"])
        #expect(navigator.itemActions.map(\.itemKind) == [.folder, .app])
    }

    @Test func leavesOutTheActionsOfTheSelectedFeature() {
        let modules: [any FeatureModule] = [
            FakeFeature("duplicates", in: .files, offering: [.folder]),
            FakeFeature("uninstaller", in: .applications, offering: [.app])
        ]
        let navigator = FeatureNavigator(modules: modules, selectedID: "uninstaller")

        #expect(navigator.itemActions.map(\.featureID) == ["duplicates"])

        navigator.open("duplicates")
        #expect(navigator.itemActions.map(\.featureID) == ["uninstaller"])
    }

    @Test func offersNothingWhenNoFeatureTakesItems() {
        let navigator = FeatureNavigator(modules: [FakeFeature("disk-map", in: .files)], selectedID: nil)

        #expect(navigator.itemActions.isEmpty)
    }

    @Test func offersAnItemOnlyToTheFeaturesThatTakeIt() {
        let library = URL(filePath: "/Users/test/Library")
        let documents = URL(filePath: "/Users/test/Documents")
        let app = URL(filePath: "/Applications/Zoom.app")
        let modules: [any FeatureModule] = [
            FakeFeature("disk-map", in: .files),
            FakeFeature("duplicates", in: .files, offering: [.folder], refusing: [library]),
            FakeFeature("large-files", in: .files, offering: [.folder]),
            FakeFeature("uninstaller", in: .applications, offering: [.app])
        ]
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")
        let actions = navigator.featureItemActions

        #expect(actions.offered(for: .folder, at: library).map(\.featureID) == ["large-files"])
        #expect(actions.offered(for: .folder, at: documents).map(\.featureID) == ["duplicates", "large-files"])
        #expect(actions.offered(for: .app, at: app).map(\.featureID) == ["uninstaller"])
    }

    @Test func carriesOutNoActionOfAFeatureItDoesNotHave() throws {
        let navigator = FeatureNavigator(
            modules: [FakeFeature("duplicates", in: .files, offering: [.folder])],
            selectedID: nil
        )
        let offered = try #require(navigator.itemActions.first)
        let unknown = FeatureItemAction(featureID: "gone", itemKind: .folder, title: "gone", symbolName: "circle")
        let documents = URL(filePath: "/Users/test/Documents")

        #expect(navigator.canPerform(offered, on: documents))
        #expect(!navigator.canPerform(unknown, on: documents))
    }
}
