@testable import CleanMacApp
import CleanMacUI
import Testing

struct UpcomingFeatureTests {
    /// The sidebar's selection is the string identifier of a feature. A planned feature
    /// identified by a string too could be selected on macOS 13, which can't switch
    /// selection off row by row.
    @Test func plannedFeaturesAreNotIdentifiedByTheSelectionType() {
        let privacy = UpcomingFeature(title: "Privacy", symbolName: "hand.raised.fill", section: .cleanup)

        #expect(!((privacy.id as Any) is String))
    }

    @Test func plannedFeaturesWithDifferentTitlesHaveDifferentIdentities() {
        let privacy = UpcomingFeature(title: "Privacy", symbolName: "hand.raised.fill", section: .cleanup)
        let monitor = UpcomingFeature(title: "Monitor", symbolName: "power", section: .performance)

        #expect(privacy.id != monitor.id)
    }
}
