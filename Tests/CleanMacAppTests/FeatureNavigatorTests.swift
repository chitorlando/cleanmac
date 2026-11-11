@testable import CleanMacApp
import CleanMacUI
import Testing

@MainActor
struct FeatureNavigatorTests {
    private let modules: [any FeatureModule] = [
        FakeFeature("disk-map", in: .files),
        FakeFeature("uninstaller", in: .applications)
    ]

    @Test func startsOnTheGivenFeature() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        #expect(navigator.selectedModule?.id == "disk-map")
    }

    @Test func opensAnotherFeatureByItsID() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        navigator.open("uninstaller")

        #expect(navigator.selectedID == "uninstaller")
        #expect(navigator.selectedModule?.id == "uninstaller")
    }

    @Test func ignoresIDsThatMatchNoFeature() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        navigator.open("privacy")

        #expect(navigator.selectedID == "disk-map")
    }

    @Test func featuresOpenEachOtherThroughTheAction() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        navigator.openFeatureAction("uninstaller")

        #expect(navigator.selectedID == "uninstaller")
    }

    @Test func theDefaultActionDoesNothing() {
        OpenFeatureAction.none("uninstaller")
    }
}
