/// Decides which items of a folder are too small to show on their own in the disk map.
///
/// An item is small when it takes up less than `minimumShare` of its folder, so a folder
/// never lists more than about `1 / minimumShare` items, however many it holds.
public struct SmallItemGrouping: Equatable, Sendable {
    /// 1 %: in a chart of the folder, a slice narrower than that is hard to see or point at.
    public static let defaultMinimumShare = 0.01

    /// Fraction of its folder's size, from 0 to 1, that an item needs to be shown on its own.
    /// Zero shows every item.
    public let minimumShare: Double

    public init(minimumShare: Double = defaultMinimumShare) {
        self.minimumShare = min(max(minimumShare, 0), 1)
    }

    /// Whether an item of `size` bytes is too small to show on its own in a folder of `folderSize` bytes.
    public func isSmall(_ size: Int64, inFolderOf folderSize: Int64) -> Bool {
        Double(size) < Double(folderSize) * minimumShare
    }
}
