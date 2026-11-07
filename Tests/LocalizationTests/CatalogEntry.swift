/// One key of a String Catalog with its translations.
struct CatalogEntry: Decodable, Sendable {
    let extractionState: String?
    let localizations: [String: Localization]?

    /// The key is no longer used by the code.
    var isStale: Bool {
        extractionState == "stale"
    }

    func localization(for language: String) -> Localization? {
        localizations?[language]
    }
}
