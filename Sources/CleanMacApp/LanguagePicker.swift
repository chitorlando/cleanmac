import CleanMacCore
import CleanMacUI
import SwiftUI

/// Row of the Settings window that chooses the language of the app.
struct LanguagePicker: View {
    let preferences: Preferences

    var body: some View {
        SettingPicker(
            AppSettings.language,
            in: preferences,
            title: Text("Language", bundle: .module, comment: "Setting of the app: the language it is shown in."),
            note: Text("Takes effect the next time you open CleanMac.", bundle: .module, comment: "Note under the language setting.")
        ) { language in
            language.title
        }
    }
}
