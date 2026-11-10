/// A value derived from others, computed on first use and kept until one of them changes.
///
/// Every view that observes an `ObservableObject` is evaluated again on any change, and
/// each reads the derived values it shows. Keeping them computes each one once per change
/// instead of once per reader.
struct Memoized<Value> {
    private var value: Value?

    /// Forgets the value, so the next read computes it again.
    mutating func invalidate() {
        value = nil
    }

    mutating func value(computedBy compute: () -> Value) -> Value {
        if let value {
            return value
        }
        let computed = compute()
        value = computed
        return computed
    }
}
