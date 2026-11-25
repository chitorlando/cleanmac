import SwiftUI

/// What a feature adds to the Settings window: the controls of one or more of its settings,
/// and the section they go under.
///
/// A feature defines its settings and builds the controls that change them, usually with
/// `SettingPicker`, and lists them in `FeatureModule.settings`. The app shell puts the items
/// of every feature under their sections, without knowing what each one holds.
public struct SettingsItem: Identifiable {
    /// Unique among the items of the window, such as the key of the setting.
    public let id: String
    public let section: SettingsSection
    private let content: @MainActor () -> AnyView

    /// - Parameter content: The controls, as rows of a form.
    public init<Content: View>(
        id: String,
        section: SettingsSection,
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) {
        self.id = id
        self.section = section
        self.content = { AnyView(content()) }
    }

    @MainActor
    public func makeView() -> AnyView {
        content()
    }
}
