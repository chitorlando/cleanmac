import CleanMacUI
import SwiftUI

/// Space on the startup volume and the home folder's, with a way to the disk map.
struct DiskCard: View {
    let volumes: [VolumeCapacity]
    let diskMapFeatureID: String?
    let theme: FeatureTheme
    @Environment(\.openFeature) private var openFeature

    var body: some View {
        MonitorCard(title: Text("Disk", bundle: .module, comment: "Title of the disk section of the monitor."), symbolName: "internaldrive", theme: theme) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(volumes) { volume in
                    VolumeRow(volume: volume, theme: theme)
                }
                if volumes.isEmpty {
                    Text(verbatim: "—").foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let diskMapFeatureID {
                    Button {
                        openFeature(diskMapFeatureID)
                    } label: {
                        Label {
                            Text("Open Disk Map", bundle: .module, comment: "Button that opens the disk map feature from the monitor.")
                        } icon: {
                            Image(systemName: "chart.pie.fill")
                        }
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}
