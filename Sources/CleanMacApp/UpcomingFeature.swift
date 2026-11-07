import CleanMacUI
import Foundation

/// A planned feature shown in the sidebar until it is implemented.
struct UpcomingFeature: Identifiable {
    let title: String
    let symbolName: String

    var id: String { title }
}

extension UpcomingFeature {
    static let roadmap: [UpcomingFeature] = [
        UpcomingFeature(
            title: String(localized: "Uninstaller", bundle: .module, comment: "Upcoming feature name in the sidebar."),
            symbolName: "app.badge.checkmark"
        ),
        UpcomingFeature(
            title: String(localized: "Disk Map", bundle: .module, comment: "Upcoming feature name in the sidebar."),
            symbolName: "chart.pie.fill"
        ),
        UpcomingFeature(
            title: String(localized: "Duplicates", bundle: .module, comment: "Upcoming feature name in the sidebar."),
            symbolName: "doc.on.doc.fill"
        ),
        UpcomingFeature(
            title: String(localized: "Privacy", bundle: .module, comment: "Upcoming feature name in the sidebar."),
            symbolName: "hand.raised.fill"
        ),
        UpcomingFeature(
            title: String(localized: "Login Items", bundle: .module, comment: "Upcoming feature name in the sidebar."),
            symbolName: "power"
        ),
        UpcomingFeature(
            title: String(localized: "Maintenance", bundle: .module, comment: "Upcoming feature name in the sidebar."),
            symbolName: "wrench.and.screwdriver.fill"
        ),
        UpcomingFeature(
            title: String(
                localized: "Monitor",
                bundle: .module,
                comment: "Upcoming feature name in the sidebar: system monitor for CPU, memory and disk."
            ),
            symbolName: "gauge.with.dots.needle.67percent"
        )
    ]
}
