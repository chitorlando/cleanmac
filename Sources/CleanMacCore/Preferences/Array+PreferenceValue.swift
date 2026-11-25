/// Lists of strings, such as the paths of folders.
extension Array: PreferenceValue where Element == String {
    public init?(propertyListValue: Any) {
        guard let strings = propertyListValue as? [String] else { return nil }
        self = strings
    }

    public var propertyListValue: Any { self }
}
