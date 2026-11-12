import CleanMacUI
import SwiftUI

/// Processor use now, split into user and system time, with its recent history.
struct CPUCard: View {
    let usage: CPUUsage?
    let history: SampleHistory<CPUUsage>
    let theme: FeatureTheme

    var body: some View {
        MonitorCard(title: Text("CPU", bundle: .module, comment: "Title of the processor section of the monitor."), symbolName: "cpu", theme: theme) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                PercentText(value: usage?.total)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                VStack(alignment: .leading, spacing: 2) {
                    LegendRow(color: theme.primary, title: Text("User", bundle: .module, comment: "Processor time spent on apps and other user code."), value: usage?.user)
                    LegendRow(color: theme.secondary, title: Text("System", bundle: .module, comment: "Processor time spent by the system."), value: usage?.system)
                }
                .font(.caption)
            }
            CPUHistoryChart(history: history, theme: theme)
                .frame(height: 60)
        }
    }
}
