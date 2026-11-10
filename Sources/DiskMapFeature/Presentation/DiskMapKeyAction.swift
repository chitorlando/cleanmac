/// What a key press asks of the disk map.
enum DiskMapKeyAction: Equatable, Sendable {
    /// Moves the highlight that many items down the list, or up when negative.
    case moveHighlight(by: Int)
    /// Opens the highlighted folder.
    case openHighlighted
    /// Goes to the folder that holds the focused one.
    case goUp
}
