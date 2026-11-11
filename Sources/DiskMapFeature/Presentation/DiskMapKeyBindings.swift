/// Decides what each key does in the disk map.
///
/// ↑ and ↓ move through the items, → or Return opens the highlighted folder and ← goes up,
/// also while something is selected: moving the selection to the Trash takes a click.
struct DiskMapKeyBindings: Sendable {
    /// What `key` does, or `nil` when the map leaves it to whoever comes next.
    func action(for key: DiskMapKey) -> DiskMapKeyAction? {
        switch key {
        case .downArrow: .moveHighlight(by: 1)
        case .upArrow: .moveHighlight(by: -1)
        case .rightArrow, .return: .openHighlighted
        case .leftArrow: .goUp
        }
    }
}
