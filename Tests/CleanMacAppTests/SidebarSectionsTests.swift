@testable import CleanMacApp
import CleanMacUI
import Testing

@MainActor
struct SidebarSectionsTests {
    @Test func firstModuleFollowsTheSectionOrderRatherThanRegistration() {
        let sections = SidebarSections(
            modules: [
                FakeFeature("maintenance", in: .performance),
                FakeFeature("large-files", in: .files),
                FakeFeature("uninstaller", in: .applications),
                FakeFeature("system-junk", in: .cleanup)
            ],
            upcoming: []
        )

        #expect(sections.firstModule?.id == "system-junk")
    }

    @Test func firstModuleKeepsTheRegistrationOrderWithinASection() {
        let sections = SidebarSections(
            modules: [FakeFeature("duplicates", in: .files), FakeFeature("large-files", in: .files)],
            upcoming: []
        )

        #expect(sections.firstModule?.id == "duplicates")
    }

    @Test func plannedFeaturesAreListedButNeverSelectedFirst() {
        let privacy = UpcomingFeature(title: "Privacy", symbolName: "hand.raised.fill", section: .cleanup)
        let sections = SidebarSections(modules: [FakeFeature("uninstaller", in: .applications)], upcoming: [privacy])

        #expect(sections.visibleSections == [.cleanup, .applications])
        #expect(sections.firstModule?.id == "uninstaller")
    }

    @Test func sectionsWithoutFeaturesAreHidden() {
        let sections = SidebarSections(modules: [FakeFeature("maintenance", in: .performance)], upcoming: [])

        #expect(sections.visibleSections == [.performance])
    }

    @Test func noFeaturesMeansNothingToSelect() {
        #expect(SidebarSections(modules: [], upcoming: []).firstModule == nil)
    }
}
