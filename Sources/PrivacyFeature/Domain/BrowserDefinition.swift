/// A browser CleanMac knows, and where it keeps its caches.
public struct BrowserDefinition: Identifiable, Hashable, Sendable {
    public let name: String
    public let bundleID: String
    public let cacheLocations: [CacheLocation]

    public var id: String { bundleID }

    public init(name: String, bundleID: String, cacheLocations: [CacheLocation]) {
        self.name = name
        self.bundleID = bundleID
        self.cacheLocations = cacheLocations
    }
}
