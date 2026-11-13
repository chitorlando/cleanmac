/// Whether an item's context menu offers to select or deselect it.
public enum ItemMenuSelection: Hashable, Sendable {
    /// The item can't be selected, such as a running app or a protected folder.
    case unavailable
    case selected
    case deselected

    /// - Parameters:
    ///   - isSelected: The item is selected now.
    ///   - canChange: The selection can change; `false` for locked items.
    public init(isSelected: Bool, canChange: Bool) {
        if !canChange {
            self = .unavailable
        } else {
            self = isSelected ? .selected : .deselected
        }
    }
}
