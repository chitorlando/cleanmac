import CleanMacUI
import Foundation

/// A planned feature shown in the sidebar until it is implemented.
struct UpcomingFeature: Identifiable {
    /// Identity of a planned feature, a type of its own on purpose.
    ///
    /// The sidebar selects features by their string identifier, and a list can only select
    /// the rows whose identity has the type of its selection. With an identity of another
    /// type, a planned feature can't be selected by click or keyboard on any system.
    /// Before macOS 14 there's no other way to keep a row out of the selection.
    struct ID: Hashable {
        let title: String
    }

    let title: String
    let symbolName: String
    let section: FeatureSection

    var id: ID { ID(title: title) }
}

extension UpcomingFeature {
    /// Every planned feature is available now. Add one here to show it in the sidebar
    /// with the "Soon" badge until it's implemented.
    static let roadmap: [UpcomingFeature] = []
}
