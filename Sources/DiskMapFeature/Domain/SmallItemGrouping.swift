/// Decides which items of a folder are too small to show on their own in the disk map.
///
/// An item is small when it takes up less than `minimumShare` of its folder and less than
/// `minimumSize`. Empty items are always small. So a folder lists its large items and,
/// of the rest, about `1 / minimumShare` at most, however many it holds.
public struct SmallItemGrouping: Equatable, Sendable {
    /// 1 %: in a chart of the folder, a slice narrower than that is hard to see or point at.
    public static let defaultMinimumShare = 0.01
    /// 10 MB: a single item smaller than that rarely matters when freeing space,
    /// and the folder that holds many of them still shows what they add up to.
    public static let defaultMinimumSize: Int64 = 10_000_000
    /// Shows every item on its own, even empty ones.
    public static let off = SmallItemGrouping(minimumShare: 0, minimumSize: 0)

    /// Fraction of its folder's size, from 0 to 1, that is enough for an item to be shown on its own.
    public let minimumShare: Double
    /// Bytes that are enough for an item to be shown on its own, whatever its share.
    public let minimumSize: Int64

    public init(minimumShare: Double = defaultMinimumShare, minimumSize: Int64 = defaultMinimumSize) {
        self.minimumShare = min(max(minimumShare, 0), 1)
        self.minimumSize = max(minimumSize, 0)
    }

    /// Whether an item of `size` bytes is too small to show on its own in a folder of `folderSize` bytes.
    public func isSmall(_ size: Int64, inFolderOf folderSize: Int64) -> Bool {
        guard size < minimumSize else { return false }
        return size == 0 || Double(size) < Double(folderSize) * minimumShare
    }
}
