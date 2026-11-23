/// `PreferenceStorage` that forgets everything when it goes away, for tests and previews.
@MainActor
public final class InMemoryPreferenceStorage: PreferenceStorage {
    private var values: [String: Any]

    /// - Parameter values: What is kept from the start, by key.
    public init(_ values: [String: Any] = [:]) {
        self.values = values
    }

    public func value(forKey key: String) -> Any? {
        values[key]
    }

    public func set(_ value: Any, forKey key: String) {
        values[key] = value
    }

    public func removeValue(forKey key: String) {
        values[key] = nil
    }
}
