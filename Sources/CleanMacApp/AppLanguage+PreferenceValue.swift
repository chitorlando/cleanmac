import CleanMacCore
import Foundation

/// Kept the way macOS keeps the languages a user prefers for an app: a list of language
/// identifiers, the favorite first. No list is the system's choice.
extension AppLanguage: PreferenceValue {
    /// The language of the first identifier, whatever its script or region, such as `es-419`.
    /// `nil` when the app has no such language.
    init?(propertyListValue: Any) {
        guard let identifiers = propertyListValue as? [String],
              let favorite = identifiers.first,
              let code = Locale.Language(identifier: favorite).languageCode?.identifier,
              let language = Self.allCases.first(where: { $0.code == code }) else {
            return nil
        }
        self = language
    }

    var propertyListValue: Any {
        code.map { [$0] } ?? [String]()
    }
}
