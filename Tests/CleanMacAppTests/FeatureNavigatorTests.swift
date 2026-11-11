@testable import CleanMacApp
import CleanMacUI
import Foundation
import Testing

@MainActor
struct FeatureNavigatorTests {
    private let diskMap = FakeFeature("disk-map", in: .files)
    private let uninstaller = FakeFeature("uninstaller", in: .applications)
    private var modules: [any FeatureModule] { [diskMap, uninstaller] }
    private let app = URL(filePath: "/Applications/Zoom.app")

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

    @Test func asksTheOpenedFeatureToShowTheItem() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        navigator.openFeatureAction("uninstaller", showing: app)

        #expect(navigator.selectedID == "uninstaller")
        #expect(uninstaller.shownItems == [app])
        #expect(diskMap.shownItems.isEmpty)
    }

    @Test func showsNoItemWhenOnlyTheFeatureIsAskedFor() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        navigator.open("uninstaller")

        #expect(uninstaller.shownItems.isEmpty)
    }

    @Test func noFeatureIsAskedToShowAnItemForAnUnknownID() {
        let navigator = FeatureNavigator(modules: modules, selectedID: "disk-map")

        navigator.open("privacy", showing: app)

        #expect(navigator.selectedID == "disk-map")
        #expect(diskMap.shownItems.isEmpty && uninstaller.shownItems.isEmpty)
    }

    @Test func theDefaultActionDoesNothing() {
        OpenFeatureAction.none("uninstaller")
        OpenFeatureAction.none("uninstaller", showing: app)
    }
}
