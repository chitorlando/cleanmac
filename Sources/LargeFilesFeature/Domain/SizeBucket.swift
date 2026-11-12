/// Size ranges the user can filter large files by.
///
/// The first range has no lower limit of its own: it starts at the smallest size the scan
/// looks for, `LargeFileCriteria.minimumSize`, so the ranges always agree with the criteria.
public enum SizeBucket: CaseIterable, Sendable {
    case upTo100MB
    case from100MBTo1GB
    case over1GB

    /// The bucket of a file of `size` bytes.
    public init(size: Int64) {
        self = Self.allCases.first { bucket in
            bucket.upperLimit.map { size < $0 } ?? true
        } ?? .over1GB
    }

    /// Bytes from which files belong to the next bucket, or `nil` for the last one.
    public var upperLimit: Int64? {
        switch self {
        case .upTo100MB: 100 * ByteSize.megabyte
        case .from100MBTo1GB: ByteSize.gigabyte
        case .over1GB: nil
        }
    }

    /// Smallest size of the bucket's files when the scan only finds files of `minimumSize` or more.
    public func lowerLimit(forMinimumSize minimumSize: Int64) -> Int64 {
        switch self {
        case .upTo100MB: minimumSize
        case .from100MBTo1GB: max(100 * ByteSize.megabyte, minimumSize)
        case .over1GB: max(ByteSize.gigabyte, minimumSize)
        }
    }

    /// Buckets that can hold files of `minimumSize` or more, smallest first.
    public static func buckets(forMinimumSize minimumSize: Int64) -> [SizeBucket] {
        allCases.filter { bucket in
            bucket.upperLimit.map { minimumSize < $0 } ?? true
        }
    }
}
