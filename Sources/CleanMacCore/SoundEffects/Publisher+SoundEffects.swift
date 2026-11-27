import Combine

public extension Publisher where Output: Equatable, Failure == Never {
    /// The sound effects that the changes of the published values call for, such as the moves
    /// of a screen from one phase to the next.
    ///
    /// The first value is where the changes start, so it calls for none. Nor does a value equal
    /// to the one before it, which `@Published` sends each time a property is set, even to what
    /// it already was.
    ///
    /// - Parameter effect: The sound effect that a change from the first value to the second
    ///   calls for, or `nil` for none.
    func soundEffects(_ effect: @escaping (_ old: Output, _ new: Output) -> SoundEffect?) -> AnyPublisher<SoundEffect, Never> {
        scan((old: Output?.none, new: Output?.none)) { change, value in
            (old: change.new, new: value)
        }
        .compactMap { change -> SoundEffect? in
            guard let old = change.old, let new = change.new, old != new else { return nil }
            return effect(old, new)
        }
        .eraseToAnyPublisher()
    }
}
