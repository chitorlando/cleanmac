/// Finds installed apps with their leftovers, reporting progress as a stream of events.
public protocol InstalledAppScanning: Sendable {
    func scan() -> AsyncStream<AppScanEvent>
}
