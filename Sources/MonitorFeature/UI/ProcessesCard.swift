import CleanMacUI
import SwiftUI

/// The user's busiest processes, by processor or memory as chosen.
struct ProcessesCard: View {
    let processes: [ProcessUsage]
    @Binding var ranking: ProcessRanking
    let theme: FeatureTheme

    var body: some View {
        MonitorCard(
            title: Text("Top Processes", bundle: .module, comment: "Title of the list of the busiest processes."),
            symbolName: "list.number",
            theme: theme
        ) {
            Picker(selection: $ranking) {
                ForEach(ProcessRanking.allCases, id: \.self) { ranking in
                    ranking.title.tag(ranking)
                }
            } label: {
                Text("Order by", bundle: .module, comment: "Label of the control that orders the busiest processes.")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        } content: {
            if processes.isEmpty {
                Text("Measuring…", bundle: .module, comment: "Shown before the first readings of the busiest processes.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(processes) { process in
                        ProcessRow(process: process, ranking: ranking)
                    }
                }
            }
            Spacer(minLength: 0)
            Text("Only your own processes are listed.", bundle: .module, comment: "Note under the busiest processes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
