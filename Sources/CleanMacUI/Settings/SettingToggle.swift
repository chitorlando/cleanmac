import CleanMacCore
import SwiftUI

/// Row of the Settings window that turns a setting on or off.
///
/// Shows the user's choice and keeps a new one in the preferences as soon as it's made. A
/// choice made elsewhere while the row is on view, such as from the menu bar, shows at once.
public struct SettingToggle: View {
    private let setting: Setting<Bool>
    private let preferences: Preferences
    private let title: Text
    private let note: Text?

    @State private var isOn: Bool

    /// - Parameters:
    ///   - title: Name of the setting.
    ///   - note: What the user has to know about the setting, shown under its name.
    public init(_ setting: Setting<Bool>, in preferences: Preferences, title: Text, note: Text? = nil) {
        self.setting = setting
        self.preferences = preferences
        self.title = title
        self.note = note
        _isOn = State(initialValue: preferences.value(of: setting))
    }

    public var body: some View {
        Toggle(isOn: selection) {
            SettingLabel(title: title, note: note)
        }
        .onReceive(preferences.changes(of: setting)) { isOn = $0 }
    }

    private var selection: Binding<Bool> {
        Binding {
            isOn
        } set: { newValue in
            isOn = newValue
            preferences.set(newValue, for: setting)
        }
    }
}
