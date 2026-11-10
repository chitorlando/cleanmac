import SwiftUI

/// The focused folder in the center with its items in rings around it.
///
/// Pointing at a slice highlights its branch, also in the list, and shows the slice in the
/// center. Clicking a slice opens the folder of its branch, and clicking the center goes up.
/// VoiceOver reads the list instead, which has the same items.
struct SunburstChart: View {
    private static let holeRadius: CGFloat = 0.36
    private static let ringGap: CGFloat = 0.01

    let folder: DiskNode
    let segments: [RingSegment]
    let ringCount: Int
    let highlightedBranch: Int?
    let onPoint: (RingSegment?) -> Void
    let onOpen: (RingSegment) -> Void
    let onCenter: () -> Void

    @State private var pointed: RingSegment?

    var body: some View {
        ZStack {
            ForEach(segments) { segment in
                slice(segment)
            }
            DiskMapCenterLabel(name: pointedName, size: pointed?.size ?? folder.size)
                .frame(width: 150)
                .onTapGesture(perform: onCenter)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var pointedName: String? {
        guard let pointed else { return folder.name }
        return pointed.node?.name
    }

    private func slice(_ segment: RingSegment) -> some View {
        let thickness = (1 - Self.holeRadius) / CGFloat(ringCount)
        let shape = RingSegmentShape(
            startDegrees: segment.startDegrees,
            endDegrees: segment.endDegrees,
            innerRadius: Self.holeRadius + thickness * CGFloat(segment.ring) + Self.ringGap,
            outerRadius: Self.holeRadius + thickness * CGFloat(segment.ring + 1)
        )
        return shape
            .fill(SegmentPalette.color(for: segment))
            .overlay(shape.stroke(Color.black.opacity(0.35), lineWidth: 0.75))
            .opacity(isDimmed(segment) ? 0.4 : 1)
            .contentShape(shape)
            .onHover { inside in
                if inside {
                    pointed = segment
                    onPoint(segment)
                } else if pointed?.id == segment.id {
                    pointed = nil
                    onPoint(nil)
                }
            }
            .onTapGesture { onOpen(segment) }
            .animation(.snappy(duration: 0.15), value: highlightedBranch)
    }

    private func isDimmed(_ segment: RingSegment) -> Bool {
        guard let highlightedBranch else { return false }
        return segment.branch != highlightedBranch
    }
}
