import Foundation

/// A kind of junk shown to the user, such as user caches or logs.
public struct JunkCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let symbolName: String
    /// How cleaning gets rid of the category's items.
    public let removal: JunkRemoval
    /// Whether its items are selected after a scan. Most junk is safe to remove, so they are;
    /// the user picks those of the other categories, such as the Trash, which is erased for good.
    public let preselectsItems: Bool

    public init(
        id: String,
        title: String,
        summary: String,
        symbolName: String,
        removal: JunkRemoval = .moveToTrash,
        preselectsItems: Bool = true
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.symbolName = symbolName
        self.removal = removal
        self.preselectsItems = preselectsItems
    }
}

/// How cleaning gets rid of the items of a junk category.
public enum JunkRemoval: Hashable, Sendable {
    /// Each item goes to the Trash, where the user can put it back.
    case moveToTrash
    /// The Trash is emptied, which erases all its bins at once, for good.
    case emptyTrash
}
