import Foundation

/// Group of related features in the sidebar, listed in this order.
public enum FeatureSection: CaseIterable, Identifiable, Sendable {
    case cleanup
    case applications
    case files
    case performance

    public var id: Self { self }

    /// Section title shown in the sidebar.
    public var title: String {
        switch self {
        case .cleanup:
            String(localized: "Cleanup", bundle: .module, comment: "Sidebar section with features that remove junk.")
        case .applications:
            String(localized: "Applications", bundle: .module, comment: "Sidebar section with features that manage apps.")
        case .files:
            String(localized: "Files", bundle: .module, comment: "Sidebar section with features that find large or repeated files.")
        case .performance:
            String(localized: "Performance", bundle: .module, comment: "Sidebar section with features that keep the Mac running smoothly.")
        }
    }
}
