/// Finds the caches of the installed browsers.
public protocol BrowserCacheScanning: Sendable {
    func scan() async -> [BrowserCaches]
}
