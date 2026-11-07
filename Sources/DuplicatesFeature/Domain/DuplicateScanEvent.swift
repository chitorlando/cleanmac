/// What a duplicate scan reports while it runs.
public enum DuplicateScanEvent: Hashable, Sendable {
    case progress(DuplicateScanProgress)
    case found(DuplicateGroup)
}
