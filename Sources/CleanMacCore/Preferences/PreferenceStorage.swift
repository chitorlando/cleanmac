/// Where the preferences are kept: property list values under string keys.
@MainActor
public protocol PreferenceStorage {
    /// The value kept under `key`, if there is one.
    func value(forKey key: String) -> Any?

    /// Keeps `value`, a property list value, under `key`.
    func set(_ value: Any, forKey key: String)

    /// Forgets the value kept under `key`.
    func removeValue(forKey key: String)
}
