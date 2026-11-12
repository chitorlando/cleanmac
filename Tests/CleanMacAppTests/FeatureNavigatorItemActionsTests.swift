@testable import CleanMacApp
import CleanMacUI
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

    @Test func offersNothingWhenNoFeatureTakesItems() {
        let navigator = FeatureNavigator(modules: [FakeFeature("disk-map", in: .files)], selectedID: nil)

        #expect(navigator.itemActions.isEmpty)
    }
}
