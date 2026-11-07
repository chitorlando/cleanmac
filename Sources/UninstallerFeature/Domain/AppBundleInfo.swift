import Foundation

/// Identity of an installed application bundle, as declared in its Info.plist.
public struct AppBundleInfo: Identifiable, Hashable, Sendable {
    public let url: URL
    public let bundleID: String
    /// File name of the bundle without the ".app" extension.
    public let name: String
    /// Marketing version (`CFBundleShortVersionString`), when declared.
    public let version: String?
    /// `CFBundleName` and `CFBundleDisplayName` when they differ from `name`.
    public let alternateNames: [String]

    public var id: URL { url }

    public init(
        url: URL,
        bundleID: String,
        name: String,
        version: String? = nil,
        alternateNames: [String] = []
    ) {
        self.url = url
        self.bundleID = bundleID
        self.name = name
        self.version = version
        self.alternateNames = alternateNames
    }
}
