import Charts
import CleanMacUI
import SwiftUI

/// Processor use over the last readings, oldest on the left, with system time at the bottom.
struct CPUHistoryChart: View {
    let history: SampleHistory<CPUUsage>
    let theme: FeatureTheme

    var body: some View {
        let points = Array(history.values.enumerated())
        Chart(points, id: \.offset) { point in
            AreaMark(
                x: .value("Reading", point.offset),
                yStart: .value("Start", 0),
                yEnd: .value("System", point.element.system)
            )
            .foregroundStyle(theme.secondary.opacity(0.8))
            AreaMark(
                x: .value("Reading", point.offset),
                yStart: .value("System", point.element.system),
                yEnd: .value("Total", point.element.total)
            )
            .foregroundStyle(theme.primary.opacity(0.7))
        }
        .chartXScale(domain: 0...max(history.capacity - 1, 1))
        .chartYScale(domain: 0...1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 8))
        .accessibilityElement()
        .accessibilityLabel(Text("Processor history", bundle: .module, comment: "Accessibility label of the chart of recent processor use."))
    }
}
