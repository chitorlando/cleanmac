import SwiftUI

extension AppLanguage {
    /// Name of the language in the Settings window. Each language is named in itself,
    /// so it can be found whatever the language of the app.
    var title: Text {
        switch self {
        case .system: Text("System Default", bundle: .module, comment: "Choice of the language setting: the language macOS picks for the app.")
        case .english: Text(verbatim: "English")
        case .spanish: Text(verbatim: "Español")
        }
    }
}
