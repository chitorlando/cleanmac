import CleanMacCore

/// A file or folder an app keeps in the user's Library.
public struct Leftover: Identifiable, Hashable, Sendable {
    public let item: CleanableItem
    public let kind: LeftoverKind

    public var id: CleanableItem.ID { item.id }

    public init(item: CleanableItem, kind: LeftoverKind) {
        self.item = item
        self.kind = kind
    }
}
