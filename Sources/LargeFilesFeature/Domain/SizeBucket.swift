/// Size ranges the user can filter large files by.
public enum SizeBucket: CaseIterable, Sendable {
    case from50MBTo100MB
    case from100MBTo1GB
    case over1GB

    /// The bucket of a file of `size` bytes, or `nil` below 50 MB.
    public init?(size: Int64) {
        switch size {
        case ..<(50 * ByteSize.megabyte):
            return nil
        case ..<(100 * ByteSize.megabyte):
            self = .from50MBTo100MB
        case ..<ByteSize.gigabyte:
            self = .from100MBTo1GB
        default:
            self = .over1GB
        }
    }
}
