/// What a disk map scan reports while it runs.
public enum DiskMapScanEvent: Equatable, Sendable {
    /// Files and bytes measured so far, reported every few hundred files and once at the end.
    case progress(DiskMapProgress)
    /// The map of the whole folder, the last event of a scan that runs to the end.
    case finished(DiskNode)
}
