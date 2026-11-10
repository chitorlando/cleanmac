import Foundation

/// What a slice of the disk map's rings stands for.
public enum RingSegmentContent: Equatable, Sendable {
    /// A folder, file or package.
    case item(DiskNode)
    /// The small items of `folder`, together with any item too narrow to draw on its own.
    case other(folder: URL, itemCount: Int, size: Int64)
}
