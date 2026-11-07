/// The text of one key in one language: either a simple text or variations.
struct Localization: Decodable, Sendable {
    let stringUnit: StringUnit?
    let variations: Variations?

    var hasPluralVariations: Bool {
        variations?.plural != nil
    }

    /// True when the simple text, or every plural variation, is translated.
    var isTranslated: Bool {
        if let stringUnit {
            return stringUnit.isTranslated
        }
        guard let plural = variations?.plural, plural["other"] != nil else {
            return false
        }
        return plural.values.allSatisfy(\.isTranslated)
    }
}
