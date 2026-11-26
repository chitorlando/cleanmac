import CleanMacUI
import MonitorFeature
import SwiftUI

/// The menu of the monitor in the menu bar, whose buttons bring back a main window, opening a
/// new one when none is left, and show the monitor in it through its navigator.
struct MenuBarMonitorContent: View {
    let menuBarMonitor: MenuBarMonitor
    let mainWindows: MainWindows
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        menuBarMonitor.makeMenu { [mainWindows, openWindow] in
            mainWindows.show(openingWith: openWindow)
        }
        .environment(\.openFeature, mainWindows.openFeatureAction(openingWith: openWindow))
    }
}
