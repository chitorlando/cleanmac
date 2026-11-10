import CleanMacUI
import SwiftUI

/// Name and size shown in the middle of the rings.
struct DiskMapCenterLabel: View {
    /// `nil` for the small items counted together.
    let name: String?
    let size: Int64

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let name {
                    Text(verbatim: name)
                } else {
                    Text("Other", bundle: .module, comment: "Small items of a folder, counted together in the disk map.")
                }
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            Text(size.formattedByteCount)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .contentShape(.circle)
    }
}
