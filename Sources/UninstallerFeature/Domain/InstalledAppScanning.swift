/// Finds installed apps with their leftovers, reporting progress as a stream of events.
public protocol InstalledAppScanning: Sendable {
    /// - Parameter otherApps: Apps outside the application folders to analyze with the rest,
    ///   such as one in Downloads that another feature sends to the uninstaller.
    func scan(including otherApps: [URL]) -> AsyncStream<AppScanEvent>
}

public extension InstalledAppScanning {
    /// Scans the application folders only.
    func scan() -> AsyncStream<AppScanEvent> {
        scan(including: [])
    }
}
