/// What a large-file scan reports while it runs.
public enum LargeFileScanEvent: Hashable, Sendable {
    /// Number of files looked at so far, reported every few hundred files and once at the end.
    case progress(scannedFiles: Int)
    /// A file that matches the criteria.
    case found(LargeFile)
}
