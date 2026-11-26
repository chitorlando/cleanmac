import CleanMacUI
import SwiftUI

/// The menu of the monitor in the menu bar: processor and memory use, the space left on the
/// startup disk and the busiest processes, read only while the menu is open, with ways back to
/// the app.
struct MenuBarMonitorView: View {
    private static let width: CGFloat = 320

    @ObservedObject var menuBar: MenuBarMonitor
    @ObservedObject var monitor: MonitorViewModel
    let openApp: @MainActor () -> Void
    @Environment(\.openFeature) private var openFeature

    private let theme = FeatureTheme.monitor

    var body: some View {
        let readout = MenuBarReadout(monitor.snapshot)
        FeatureScreen(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                cpu(readout.cpu)
                memory(readout.memory, pressure: readout.memoryPressure)
                disk(readout.startupVolume)
                processes(readout.busiestProcesses)
                buttons
            }
            .padding(14)
            .frame(width: Self.width)
            .fixedSize(horizontal: false, vertical: true)
        }
        // The menu's window stays around while the menu is closed, so its content can't tell
        // from appearing and disappearing when the menu opens.
        .onWindowVisibilityChange { isOpen in
            menuBar.menuVisibilityDidChange(isOpen: isOpen)
        }
    }

    private func cpu(_ usage: CPUUsage?) -> some View {
        MonitorCard(
            title: Text("CPU", bundle: .module, comment: "Title of the processor section of the monitor."),
            symbolName: "cpu",
            theme: theme
        ) {
            PercentText(value: usage?.total)
                .font(.headline)
        } content: {
            UsageBar(parts: [
                .init(id: 0, fraction: usage?.user ?? 0, color: theme.primary),
                .init(id: 1, fraction: usage?.system ?? 0, color: theme.secondary)
            ])
            HStack(spacing: 12) {
                LegendRow(color: theme.primary, title: Text("User", bundle: .module, comment: "Processor time spent on apps and other user code."), value: usage?.user)
                LegendRow(color: theme.secondary, title: Text("System", bundle: .module, comment: "Processor time spent by the system."), value: usage?.system)
            }
            .font(.caption)
        }
    }

    private func memory(_ usage: MemoryUsage?, pressure: MemoryPressure?) -> some View {
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
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                MemoryUsageBar(usage: usage, theme: theme)
            } else {
                Text(verbatim: "—").foregroundStyle(.secondary)
            }
        }
    }

    private func disk(_ volume: VolumeCapacity?) -> some View {
        MonitorCard(title: Text("Disk", bundle: .module, comment: "Title of the disk section of the monitor."), symbolName: "internaldrive", theme: theme) {
            if let volume {
                VolumeRow(volume: volume, theme: theme)
            } else {
                Text(verbatim: "—").foregroundStyle(.secondary)
            }
        }
    }

    private func processes(_ processes: [ProcessUsage]) -> some View {
        MonitorCard(
            title: Text("Top Processes", bundle: .module, comment: "Title of the list of the busiest processes."),
            symbolName: "list.number",
            theme: theme
        ) {
            if processes.isEmpty {
                Text("Measuring…", bundle: .module, comment: "Shown before the first readings of the busiest processes.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(processes) { process in
                        ProcessRow(process: process, ranking: .cpu)
                    }
                }
            }
        }
    }

    private var buttons: some View {
        HStack {
            Button {
                openApp()
            } label: {
                Label {
                    Text("Open CleanMac", bundle: .module, comment: "Button of the menu bar monitor that brings back the window of the app.")
                } icon: {
                    Image(systemName: "macwindow")
                }
            }
            Spacer(minLength: 8)
            Button {
                openFeature(menuBar.featureID)
            } label: {
                Label {
                    Text("Open Monitor", bundle: .module, comment: "Button of the menu bar monitor that shows the monitor in the window of the app.")
                } icon: {
                    Image(systemName: MonitorModule.gaugeSymbolName)
                }
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 4)
    }
}
