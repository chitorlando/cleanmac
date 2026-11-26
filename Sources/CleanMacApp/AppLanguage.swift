/// The language the app is shown in.
enum AppLanguage: CaseIterable, Hashable, Sendable {
    /// The one macOS picks for the app: the first of the user's languages the app is translated to.
    case system
    case english
    case spanish

    /// Code of the language, as macOS names it. The system's choice has none.
    var code: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .spanish: "es"
        }
    }
}
