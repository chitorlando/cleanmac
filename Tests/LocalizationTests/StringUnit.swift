/// A single translated text inside a String Catalog.
struct StringUnit: Decodable, Sendable {
    let state: String
    let value: String

    var isTranslated: Bool {
        state == "translated" && !value.isEmpty
    }
}
