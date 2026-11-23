import Combine

/// What the user chose in the settings of the app, kept from one launch to the next.
///
/// Every choice is a `Setting`. One the user never made, or whose kept value can't be used,
/// has the setting's default. Lives on the main actor: whatever works elsewhere is handed
/// the values it needs.
@MainActor
public final class Preferences {
    private let storage: any PreferenceStorage
    private let changedKeys = PassthroughSubject<String, Never>()

    public init(storage: any PreferenceStorage) {
        self.storage = storage
    }

    /// The user's choice for `setting`, or its default when nothing was kept or what was
    /// kept isn't a value the setting takes.
    public func value<Value>(of setting: Setting<Value>) -> Value {
        guard let kept = storage.value(forKey: setting.key),
              let value = Value(propertyListValue: kept),
              setting.allows(value) else {
            return setting.defaultValue
        }
        return value
    }

    /// Keeps `value` as the user's choice for `setting`, and tells whoever follows its changes.
    ///
    /// The default is kept by keeping nothing, so whoever stays with it gets the default of
    /// each version of the app. A value the setting doesn't take is ignored.
    public func set<Value>(_ value: Value, for setting: Setting<Value>) {
        guard setting.allows(value) else { return }
        let previous = self.value(of: setting)
        if value == setting.defaultValue {
            storage.removeValue(forKey: setting.key)
        } else {
            storage.set(value.propertyListValue, forKey: setting.key)
        }
        if value != previous {
            changedKeys.send(setting.key)
        }
    }

    /// Each new value of `setting`, at the moment it's chosen.
    public func changes<Value>(of setting: Setting<Value>) -> AnyPublisher<Value, Never> {
        changedKeys
            .filter { $0 == setting.key }
            .compactMap { [weak self] _ in self?.value(of: setting) }
            .eraseToAnyPublisher()
    }
}
