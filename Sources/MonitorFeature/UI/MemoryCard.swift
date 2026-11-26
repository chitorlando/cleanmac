import CleanMacUI
import SwiftUI

/// Memory in use out of the installed memory, split as Activity Monitor does, with the pressure.
struct MemoryCard: View {
    let usage: MemoryUsage?
    let pressure: MemoryPressure?
    let theme: FeatureTheme

    var body: some View {
        MonitorCard(
            title: Text("Memory", bundle: .module, comment: "Title of the memory section of the monitor."),
            symbolName: "memorychip",
            theme: theme
        ) {
            if let pressure {
                StatusBadge(pressure.title, color: pressure.color)
            }
        } content: {
            if let usage {
                MemoryUsedText(usage: usage)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                MemoryUsageBar(usage: usage, theme: theme)
                legend(usage)
            } else {
                Text(verbatim: "—").foregroundStyle(.secondary)
            }
        }
    }

    private func legend(_ usage: MemoryUsage) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 2) {
            GridRow {
                MemoryLegendRow(color: theme.primary, title: Text("App Memory", bundle: .module, comment: "Memory that apps allocated."), bytes: usage.app)
                MemoryLegendRow(color: theme.secondary, title: Text("Wired", bundle: .module, comment: "Memory the system keeps locked."), bytes: usage.wired)
            }
            GridRow {
                MemoryLegendRow(color: .purple, title: Text("Compressed", bundle: .module, comment: "Memory held compressed."), bytes: usage.compressed)
                MemoryLegendRow(color: .white.opacity(0.25), title: Text("Available", bundle: .module, comment: "Memory apps can still get."), bytes: usage.available)
            }
        }
        .font(.caption)
    }
}
