import CleanMacUI
import SwiftUI

/// The small items of the focused folder, counted together, in the gray of their slice.
struct OtherItemsRow: View {
    let itemCount: Int
    let size: Int64
    let share: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.grid.2x2.fill")
                .foregroundStyle(SegmentPalette.other)
                .frame(width: 18)
                .padding(.leading, 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Other", bundle: .module, comment: "Small items of a folder, counted together in the disk map.")
                Text(
                    "\(itemCount) small items",
                    bundle: .module,
                    comment: "Number of items too small to show one by one in the disk map."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 1) {
                Text(size.formattedByteCount)
                    .font(.callout.monospacedDigit())
                Text(share, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .fixedSize()
            .padding(.trailing, 44)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
