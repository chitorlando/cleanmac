import CleanMacCore
import CleanMacUI
import SwiftUI

/// Row of the Settings window that chooses how often the monitor takes a reading.
struct RefreshIntervalPicker: View {
    let preferences: Preferences

    var body: some View {
        SettingPicker(
            MonitorSettings.refreshInterval,
            in: preferences,
            title: Text("Update every", bundle: .module, comment: "Setting of the monitor: the time between two readings. A duration follows, such as “2 seconds”.")
        ) { seconds in
            Text("\(seconds) seconds", bundle: .module, comment: "Time between two readings of the monitor. The argument is a number of seconds.")
        }
    }
}
