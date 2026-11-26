import Foundation

/// Group of related settings in the Settings window, listed in this order.
public enum SettingsSection: CaseIterable, Identifiable, Sendable {
    /// Settings of the app as a whole, such as its language.
    case general
    /// Settings of the features that analyze the files of the user, such as what they leave out.
    case analysis
    /// Settings of the monitor.
    case monitor

    public var id: Self { self }

    /// Section title shown in the Settings window.
    public var title: String {
        switch self {
        case .general:
            String(localized: "General", bundle: .module, comment: "Section of the Settings window with settings of the whole app.")
        case .analysis:
            String(localized: "Analysis", bundle: .module, comment: "Section of the Settings window with settings of the features that analyze files.")
        case .monitor:
            String(localized: "Monitor", bundle: .module, comment: "Section of the Settings window with settings of the monitor.")
        }
    }
}
