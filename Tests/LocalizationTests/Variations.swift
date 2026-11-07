/// Alternative texts of a localization, such as one per plural category.
struct Variations: Decodable, Sendable {
    let plural: [String: Localization]?
}
