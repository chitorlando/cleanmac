import CleanMacUI
import SwiftUI

/// A volume's name, how full it is and the space left.
struct VolumeRow: View {
    let volume: VolumeCapacity
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: volume.name)
                .lineLimit(1)
                .truncationMode(.middle)
            UsageBar(parts: [.init(id: 0, fraction: volume.usedFraction, color: theme.primary)])
            Text(
                "\(volume.availableBytes.formattedByteCount) available of \(volume.totalBytes.formattedByteCount)",
                bundle: .module,
                comment: "Free space of a volume. The arguments are sizes, such as “120 GB” and “500 GB”."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
