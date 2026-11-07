/// Progress reported while scanning installed apps.
public enum AppScanEvent: Hashable, Sendable {
    /// The apps have been found; this many will be analyzed.
    case discovered(count: Int)
    /// One app has been measured together with its leftovers.
    case analyzed(InstalledApp)
}
