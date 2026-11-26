/// Settings that are on or off.
extension Bool: PreferenceValue {
    public init?(propertyListValue: Any) {
        guard let flag = propertyListValue as? Bool else { return nil }
        self = flag
    }

    public var propertyListValue: Any { self }
}
