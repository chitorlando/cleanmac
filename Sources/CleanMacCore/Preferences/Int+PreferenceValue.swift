extension Int: PreferenceValue {
    public init?(propertyListValue: Any) {
        guard let number = propertyListValue as? Int else { return nil }
        self = number
    }

    public var propertyListValue: Any { self }
}
