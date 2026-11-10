/// Decides what each key does in the disk map.
///
/// ↑ and ↓ move through the items, → or Return opens the highlighted folder and ← goes up.
/// While something is selected, Return belongs to the bar's main button, which asks before
/// moving the selection to the Trash, so the map leaves it alone.
struct DiskMapKeyBindings: Sendable {
    /// What `key` does, or `nil` when the map leaves it to whoever comes next.
    func action(for key: DiskMapKey, hasSelection: Bool) -> DiskMapKeyAction? {
        switch key {
        case .downArrow: return .moveHighlight(by: 1)
        case .upArrow: return .moveHighlight(by: -1)
        case .rightArrow: return .openHighlighted
        case .return: return hasSelection ? nil : .openHighlighted
        case .leftArrow: return .goUp
        }
    }
}
