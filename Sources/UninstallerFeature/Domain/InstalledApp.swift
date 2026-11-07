import CleanMacCore

/// An installed app with everything that must be removed to uninstall it completely.
public struct InstalledApp: Identifiable, Hashable, Sendable {
    public let info: AppBundleInfo
    public let bundle: CleanableItem
    public let leftovers: [Leftover]

    public var id: AppBundleInfo.ID { info.id }

    /// The bundle followed by every leftover.
    public var allItems: [CleanableItem] { [bundle] + leftovers.map(\.item) }

    public var totalSize: Int64 { allItems.totalSize }

    public init(info: AppBundleInfo, bundle: CleanableItem, leftovers: [Leftover]) {
        self.info = info
        self.bundle = bundle
        self.leftovers = leftovers
    }
}
