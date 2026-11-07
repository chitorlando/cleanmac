import Foundation

/// A kind of junk shown to the user, such as user caches or logs.
public struct JunkCategory: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let symbolName: String

    public init(id: String, title: String, summary: String, symbolName: String) {
        self.id = id
        self.title = title
        self.summary = summary
        self.symbolName = symbolName
    }
}
