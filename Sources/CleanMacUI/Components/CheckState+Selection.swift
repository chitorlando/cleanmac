import CleanMacCore

public extension CheckState {
    /// Maps the domain selection state to its checkbox representation.
    init(_ state: ItemSelection.State) {
        switch state {
        case .all: self = .checked
        case .some: self = .mixed
        case .none: self = .unchecked
        }
    }
}
