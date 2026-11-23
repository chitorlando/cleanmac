/// A value the preferences can keep: it turns into a property list value and back.
public protocol PreferenceValue: Equatable, Sendable {
    /// The value that was kept as `propertyListValue`, or `nil` if that isn't one.
    init?(propertyListValue: Any)

    /// The value as the preferences keep it: a string, a number, a Boolean, a date, data,
    /// or an array or a dictionary of those.
    var propertyListValue: Any { get }
}
