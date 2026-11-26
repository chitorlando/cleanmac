import CleanMacCore
import CleanMacUI
import SwiftUI

/// Rows of the Settings window that choose whether the monitor is in the menu bar, and whether
/// the processor use shows next to its icon there.
struct MenuBarSettings: View {
    let preferences: Preferences

    @State private var isShown: Bool

    init(preferences: Preferences) {
        self.preferences = preferences
        _isShown = State(initialValue: preferences.value(of: MonitorSettings.showsMenuBarExtra))
    }

    var body: some View {
        SettingToggle(
            MonitorSettings.showsMenuBarExtra,
            in: preferences,
            title: Text("Show the monitor in the menu bar", bundle: .module, comment: "Setting of the app: whether the monitor has an icon and a menu in the menu bar."),
            note: Text(
                "CleanMac keeps running when you close its window, so the menu can bring it back.",
                bundle: .module,
                comment: "Note under the setting that shows the monitor in the menu bar."
            )
        )
        SettingToggle(
            MonitorSettings.showsCPUInMenuBar,
            in: preferences,
            title: Text("Show CPU use in the menu bar", bundle: .module, comment: "Setting of the app: whether the menu bar shows the processor use next to the icon of the monitor."),
            note: Text(
                "Updates at the pace of the monitor, also while its menu is closed.",
                bundle: .module,
                comment: "Note under the setting that shows the processor use in the menu bar."
            )
        )
        .disabled(!isShown)
        .onReceive(preferences.changes(of: MonitorSettings.showsMenuBarExtra)) { isShown = $0 }
    }
}
