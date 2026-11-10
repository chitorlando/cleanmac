/// One slice of the disk map's rings.
public struct RingSegment: Identifiable, Equatable, Sendable {
    public let content: RingSegmentContent
    /// 0 for the items of the folder in the center, 1 for the items inside those, and so on.
    public let ring: Int
    /// Degrees clockwise from the top where the slice starts, from 0 to 360.
    public let startDegrees: Double
    public let endDegrees: Double
    /// Position, in the innermost ring, of the slice this one belongs to,
    /// so a whole branch can share a color.
    public let branch: Int

    public init(content: RingSegmentContent, ring: Int, startDegrees: Double, endDegrees: Double, branch: Int) {
        self.content = content
        self.ring = ring
        self.startDegrees = startDegrees
        self.endDegrees = endDegrees
        self.branch = branch
    }

    public var id: String {
        switch content {
        case .item(let node): "item:\(node.url.path)"
        case .other(let folder, _, _): "other:\(folder.path)"
        }
    }

    public var sweepDegrees: Double { endDegrees - startDegrees }

    /// The item the slice stands for, or `nil` for the small items counted together.
    public var node: DiskNode? {
        guard case .item(let node) = content else { return nil }
        return node
    }

    public var size: Int64 {
        switch content {
        case .item(let node): node.size
        case .other(_, _, let size): size
        }
    }
}
