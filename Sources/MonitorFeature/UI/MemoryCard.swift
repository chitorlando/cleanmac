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
                Text(
                    "\(bytes(usage.used)) of \(bytes(usage.physical)) used",
                    bundle: .module,
                    comment: "Memory in use out of the installed memory. The arguments are sizes, such as “9 GB” and “16 GB”."
                )
                .font(.title3.weight(.semibold))
                UsageBar(parts: [
                    .init(id: 0, fraction: share(usage.app, of: usage), color: theme.primary),
                    .init(id: 1, fraction: share(usage.wired, of: usage), color: theme.secondary),
                    .init(id: 2, fraction: share(usage.compressed, of: usage), color: .purple)
                ])
                legend(usage)
            } else {
                Text(verbatim: "—").foregroundStyle(.secondary)
            }
        }
    }

    private func legend(_ usage: MemoryUsage) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 2) {
            GridRow {
                BytesLegendRow(color: theme.primary, title: Text("App Memory", bundle: .module, comment: "Memory that apps allocated."), bytes: usage.app)
                BytesLegendRow(color: theme.secondary, title: Text("Wired", bundle: .module, comment: "Memory the system keeps locked."), bytes: usage.wired)
            }
            GridRow {
                BytesLegendRow(color: .purple, title: Text("Compressed", bundle: .module, comment: "Memory held compressed."), bytes: usage.compressed)
                BytesLegendRow(color: .white.opacity(0.25), title: Text("Available", bundle: .module, comment: "Memory apps can still get."), bytes: usage.available)
            }
        }
        .font(.caption)
    }

    private func share(_ part: UInt64, of usage: MemoryUsage) -> Double {
        usage.physical > 0 ? Double(part) / Double(usage.physical) : 0
    }

    private func bytes(_ value: UInt64) -> String {
        Int64(clamping: value).formattedByteCount
    }
}
