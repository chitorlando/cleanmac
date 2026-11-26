import CleanMacCore
import SwiftUI

/// Row of the Settings window that chooses among the values a setting allows.
///
/// Shows the user's choice and keeps a new one in the preferences as soon as it's made.
public struct SettingPicker<Value: PreferenceValue & Hashable>: View {
    private let setting: Setting<Value>
    private let preferences: Preferences
    private let title: Text
    private let note: Text?
    private let valueTitle: (Value) -> Text

    @State private var value: Value

    /// - Parameters:
    ///   - title: Name of the setting.
    ///   - note: What the user has to know about the setting, shown under its name.
    ///   - valueTitle: Name of each value the setting allows.
    public init(
        _ setting: Setting<Value>,
        in preferences: Preferences,
        title: Text,
        note: Text? = nil,
        valueTitle: @escaping (Value) -> Text
    ) {
        self.setting = setting
        self.preferences = preferences
        self.title = title
        self.note = note
        self.valueTitle = valueTitle
        _value = State(initialValue: preferences.value(of: setting))
    }

    public var body: some View {
        Picker(selection: selection) {
            ForEach(setting.allowedValues ?? [], id: \.self) { value in
                valueTitle(value).tag(value)
            }
        } label: {
            SettingLabel(title: title, note: note)
        }
    }

    private var selection: Binding<Value> {
        Binding {
            value
        } set: { newValue in
            value = newValue
            preferences.set(newValue, for: setting)
        }
    }
}
