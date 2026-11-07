import Foundation

/// Tracks which items the user has chosen to clean.
public struct ItemSelection: Equatable, Sendable {
    public enum State: Sendable {
        case all, some, none
    }

    private var selectedIDs: Set<CleanableItem.ID> = []

    public init() {}

    public var isEmpty: Bool { selectedIDs.isEmpty }

    public func contains(_ item: CleanableItem) -> Bool {
        selectedIDs.contains(item.id)
    }

    public mutating func toggle(_ item: CleanableItem) {
        if selectedIDs.remove(item.id) == nil {
            selectedIDs.insert(item.id)
        }
    }

    public mutating func select(_ items: [CleanableItem]) {
        selectedIDs.formUnion(items.map(\.id))
    }

    public mutating func deselect(_ items: [CleanableItem]) {
        selectedIDs.subtract(items.map(\.id))
    }

    /// Selects every item unless all of them are already selected, in which case it clears them.
    public mutating func toggleAll(_ items: [CleanableItem]) {
        state(of: items) == .all ? deselect(items) : select(items)
    }

    public func state(of items: [CleanableItem]) -> State {
        let count = items.count(where: contains)
        switch count {
        case 0: return .none
        case items.count: return .all
        default: return .some
        }
    }

    public func selectedItems(in items: [CleanableItem]) -> [CleanableItem] {
        items.filter(contains)
    }
}
