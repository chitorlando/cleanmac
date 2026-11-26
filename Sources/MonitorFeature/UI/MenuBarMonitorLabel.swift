import SwiftUI

/// The monitor's icon in the menu bar, with the processor use next to it when the user chose
/// to see it.
struct MenuBarMonitorLabel: View {
    @ObservedObject var menuBar: MenuBarMonitor
    /// Observed so the processor use follows each reading.
    @ObservedObject var monitor: MonitorViewModel

    var body: some View {
        if let text = menuBar.menuBarText() {
            HStack(spacing: 4) {
                icon
                Text(verbatim: text)
                    .monospacedDigit()
            }
        } else {
            icon
        }
    }

    private var icon: some View {
        Image(systemName: MonitorModule.gaugeSymbolName)
            .accessibilityLabel(Text("CleanMac Monitor", bundle: .module, comment: "Accessibility label of the icon of the monitor in the menu bar."))
    }
}
