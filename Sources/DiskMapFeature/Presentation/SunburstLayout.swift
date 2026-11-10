/// Lays out a folder of the disk map as rings around it, each slice as wide as its share of space.
///
/// The innermost ring holds the folder's items, and each further ring the items inside the
/// slice below it, `ringCount` rings in all. Slices narrower than `minimumDegrees` are hard to
/// see or point at, so they're added to their folder's small items, drawn as one gray slice
/// after the others.
public struct SunburstLayout: Sendable {
    public static let defaultRingCount = 3
    /// About 5 points along the outer ring of a chart 300 points wide.
    public static let defaultMinimumDegrees = 2.0

    public let ringCount: Int
    public let minimumDegrees: Double

    public init(ringCount: Int = defaultRingCount, minimumDegrees: Double = defaultMinimumDegrees) {
        self.ringCount = max(1, ringCount)
        self.minimumDegrees = max(0, minimumDegrees)
    }

    /// The slices around `folder`, ring by ring from the inside, each ring in clockwise order.
    public func segments(around folder: DiskNode) -> [RingSegment] {
        guard folder.size > 0 else { return [] }
        var segments: [RingSegment] = []
        addSegments(inside: folder, from: 0, sweep: 360, ring: 0, branch: nil, to: &segments)
        return segments.sorted { ($0.ring, $0.startDegrees) < ($1.ring, $1.startDegrees) }
    }

    private func addSegments(
        inside folder: DiskNode,
        from start: Double,
        sweep: Double,
        ring: Int,
        branch: Int?,
        to segments: inout [RingSegment]
    ) {
        guard ring < ringCount, folder.size > 0 else { return }
        let degreesPerByte = sweep / Double(folder.size)
        var cursor = start
        var otherCount = folder.otherItems?.itemCount ?? 0
        var otherSize = folder.otherItems?.size ?? 0

        for (index, child) in folder.children.enumerated() {
            let childSweep = Double(child.size) * degreesPerByte
            guard childSweep >= minimumDegrees else {
                otherCount += 1
                otherSize += child.size
                continue
            }
            let childBranch = branch ?? index
            segments.append(RingSegment(
                content: .item(child),
                ring: ring,
                startDegrees: cursor,
                endDegrees: cursor + childSweep,
                branch: childBranch
            ))
            addSegments(inside: child, from: cursor, sweep: childSweep, ring: ring + 1, branch: childBranch, to: &segments)
            cursor += childSweep
        }

        let otherSweep = Double(otherSize) * degreesPerByte
        guard otherSweep > 0 else { return }
        segments.append(RingSegment(
            content: .other(folder: folder.url, itemCount: otherCount, size: otherSize),
            ring: ring,
            startDegrees: cursor,
            endDegrees: cursor + otherSweep,
            branch: branch ?? folder.children.count
        ))
    }
}
