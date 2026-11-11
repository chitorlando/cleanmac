import SwiftUI

/// One slice of the disk map's rings, in the color of its branch and dimmed while the
/// highlight is on another one.
struct SunburstSlice: View {
    private static let holeRadius: CGFloat = 0.36
    private static let ringGap: CGFloat = 0.01

    let segment: RingSegment
    let ringCount: Int
    let isDimmed: Bool
    /// Gets `true` when the mouse comes over the slice and `false` when it leaves.
    let onHover: (Bool) -> Void
    let onOpen: () -> Void

    var body: some View {
        shape
            .fill(SegmentPalette.color(for: segment))
            .overlay(shape.stroke(Color.black.opacity(0.35), lineWidth: 0.75))
            .opacity(isDimmed ? 0.4 : 1)
            .contentShape(shape)
            .onHover(perform: onHover)
            .onTapGesture(perform: onOpen)
            .animation(.snappy(duration: 0.15), value: isDimmed)
    }

    private var shape: RingSegmentShape {
        let thickness = (1 - Self.holeRadius) / CGFloat(ringCount)
        return RingSegmentShape(
            startDegrees: segment.startDegrees,
            endDegrees: segment.endDegrees,
            innerRadius: Self.holeRadius + thickness * CGFloat(segment.ring) + Self.ringGap,
            outerRadius: Self.holeRadius + thickness * CGFloat(segment.ring + 1)
        )
    }
}
