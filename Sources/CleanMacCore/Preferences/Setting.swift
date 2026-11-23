/// Something the user can choose and the app remembers: the key it's kept under, its value
/// until the user chooses, and the values it can take.
///
/// Whoever uses a setting defines it, and reads and changes its value through `Preferences`.
public struct Setting<Value: PreferenceValue>: Sendable {
    /// Name the value is kept under.
    public let key: String
    /// The value until the user chooses another, and whenever what was kept can't be used.
    public let defaultValue: Value
    /// The only values the setting takes, in the order they're offered. `nil` when it takes any.
    public let allowedValues: [Value]?

    /// - Parameter allowedValues: See `allowedValues`. `defaultValue` has to be one of them.
    public init(key: String, defaultValue: Value, allowedValues: [Value]? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.allowedValues = allowedValues
    }

    /// Whether the setting takes `value`.
    public func allows(_ value: Value) -> Bool {
        allowedValues?.contains(value) ?? true
    }
}
