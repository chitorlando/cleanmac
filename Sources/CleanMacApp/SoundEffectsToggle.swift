import CleanMacCore
import CleanMacUI
import SwiftUI

/// Row of the Settings window that turns the sound effects of the app on or off (see
/// `SoundEffectSettings.isEnabled`).
struct SoundEffectsToggle: View {
    let preferences: Preferences

    var body: some View {
        SettingToggle(
            SoundEffectSettings.isEnabled,
            in: preferences,
            title: Text("Sound effects", bundle: .module, comment: "Setting of the app: whether it plays a short sound when a scan, a cleanup or maintenance ends."),
            note: Text(
                "A short sound when a scan, a cleanup or maintenance ends, unless “Play user interface sound effects” is off in the Sound settings of macOS.",
                bundle: .module,
                comment: "Note under the sound effects setting. “Play user interface sound effects” is the name of a setting in the Sound settings of macOS."
            )
        )
    }
}
