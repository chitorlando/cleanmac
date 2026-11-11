import CleanMacUI
import SwiftUI

/// Root screen of the feature: readings of the processors, memory, disks and busiest
/// processes, taken only while the screen is on view.
struct MonitorView: View {
    @ObservedObject var viewModel: MonitorViewModel
    let theme: FeatureTheme
    let diskMapFeatureID: String?

    var body: some View {
        FeatureScreen(theme: theme) {
            VStack(alignment: .leading, spacing: 16) {
                MonitorHeader()
                HStack(alignment: .top, spacing: 16) {
                    CPUCard(usage: viewModel.snapshot.cpu, history: viewModel.cpuHistory, theme: theme)
                    MemoryCard(usage: viewModel.snapshot.memory, pressure: viewModel.snapshot.memoryPressure, theme: theme)
                }
                .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .top, spacing: 16) {
                    DiskCard(volumes: viewModel.snapshot.volumes, diskMapFeatureID: diskMapFeatureID, theme: theme)
                        .frame(width: 250)
                    ProcessesCard(
                        processes: viewModel.topProcesses,
                        ranking: $viewModel.processRanking,
                        theme: theme
                    )
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(32)
            .frame(maxWidth: 1100, maxHeight: .infinity, alignment: .top)
        }
        .task { await viewModel.run() }
    }
}
