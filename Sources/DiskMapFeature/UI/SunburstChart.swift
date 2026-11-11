import SwiftUI

/// The focused folder in the center with its items in rings around it.
///
/// Pointing at a slice highlights its branch, also in the list, and shows the slice in the
/// center. Clicking a slice opens the folder of its branch, and clicking the center goes up.
/// VoiceOver reads the list instead, which has the same items.
struct SunburstChart: View {
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
                SunburstSlice(
                    segment: segment,
                    ringCount: ringCount,
                    isDimmed: isDimmed(segment),
                    onHover: { isInside in point(at: segment, isInside: isInside) },
                    onOpen: { onOpen(segment) }
                )
                .equatable()
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

    private func point(at segment: RingSegment, isInside: Bool) {
        if isInside {
            pointed = segment
            onPoint(segment)
        } else if pointed?.id == segment.id {
            pointed = nil
            onPoint(nil)
        }
    }

    private func isDimmed(_ segment: RingSegment) -> Bool {
        guard let highlightedBranch else { return false }
        return segment.branch != highlightedBranch
    }
}
