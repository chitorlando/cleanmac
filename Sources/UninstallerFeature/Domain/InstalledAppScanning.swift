import Foundation

/// Finds installed apps with their leftovers, reporting progress as a stream of events.
public protocol InstalledAppScanning: Sendable {
    /// - Parameter otherApps: Apps outside the application folders to analyze with the rest,
    ///   such as one in Downloads that another feature sends to the uninstaller.
    func scan(including otherApps: [URL]) -> AsyncStream<AppScanEvent>

    /// Whether a scan asked to include the app at `url` would list it: there is an app there
    /// that the user can remove, its identity can be read and it isn't one the scanner leaves out.
    ///
    /// It only looks at that app, so it is quick enough to ask before starting a scan.
    func canAnalyze(appAt url: URL) -> Bool
}

public extension InstalledAppScanning {
    /// Scans the application folders only.
    func scan() -> AsyncStream<AppScanEvent> {
        scan(including: [])
    }
}
