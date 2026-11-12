import Charts
import CleanMacUI
import SwiftUI

/// Processor use over the last readings, oldest on the left, user time stacked on system time.
struct CPUHistoryChart: View {
    let history: SampleHistory<CPUUsage>
    let theme: FeatureTheme

    var body: some View {
        Chart {
            ForEach(Array(history.values.enumerated()), id: \.offset) { point in
                AreaMark(x: .value("Reading", point.offset), y: .value("Usage", point.element.system))
                    .foregroundStyle(by: .value("Part", Part.system.rawValue))
                AreaMark(x: .value("Reading", point.offset), y: .value("Usage", point.element.user))
                    .foregroundStyle(by: .value("Part", Part.user.rawValue))
            }
        }
        .chartForegroundStyleScale([
            Part.system.rawValue: theme.secondary.opacity(0.85),
            Part.user.rawValue: theme.primary.opacity(0.75)
        ])
        .chartLegend(.hidden)
        .chartXScale(domain: 0...max(history.capacity - 1, 1))
        .chartYScale(domain: 0...1)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 8))
        .accessibilityElement()
        .accessibilityLabel(Text("Processor history", bundle: .module, comment: "Accessibility label of the chart of recent processor use."))
    }

    /// The two stacked series, named only to tell them apart.
    private enum Part: String {
        case system, user
    }
}
