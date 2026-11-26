/// Sizes in bytes, for one, which the app counts in `Int64`.
extension Int64: PreferenceValue {
    public init?(propertyListValue: Any) {
        guard let number = propertyListValue as? Int64 else { return nil }
        self = number
    }

    public var propertyListValue: Any { self }
}
