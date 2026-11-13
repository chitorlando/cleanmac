import CleanMacUI
import SwiftUI

/// A process with its app's icon and name, and what it uses in the chosen order.
///
/// The context menu of an app's process only shows the app in Finder: the monitor never
/// quits or stops processes.
struct ProcessRow: View {
    let process: ProcessUsage
    let ranking: ProcessRanking
    @Environment(\.fileActions) private var files

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(verbatim: process.name)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            value
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .contextMenu {
            if let appURL = process.appURL {
                Button {
                    files.showInFinder(appURL)
                } label: {
                    Label {
                        Text("Show in Finder", bundle: .module, comment: "Context menu item that reveals the app of a process in Finder.")
                    } icon: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let iconURL = process.iconURL {
            AppIconView(url: iconURL, size: 18)
        } else {
            Image(systemName: "gearshape")
                .frame(width: 18, height: 18)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var value: some View {
        switch ranking {
        case .cpu:
            Text(process.cpu, format: .percent.precision(.fractionLength(0)))
        case .memory:
            Text(Int64(clamping: process.memoryBytes).formattedByteCount)
        }
    }
}
