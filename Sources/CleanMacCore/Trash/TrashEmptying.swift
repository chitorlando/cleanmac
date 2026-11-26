/// Strategy that empties the user's Trash, which erases what it holds for good.
public protocol TrashEmptying: Sendable {
    /// Empties every bin of the user's Trash at once, as Empty Trash in Finder does.
    func emptyTrash() async throws
}
