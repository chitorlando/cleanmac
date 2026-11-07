/// The contents of a `Localizable.xcstrings` file.
struct StringCatalog: Decodable, Sendable {
    let sourceLanguage: String
    let strings: [String: CatalogEntry]

    /// Keys still used by the code, sorted for stable failure messages.
    var activeKeys: [String] {
        strings.filter { !$0.value.isStale }.keys.sorted()
    }

    var staleKeys: [String] {
        strings.filter { $0.value.isStale }.keys.sorted()
    }
}
