/// What uninstalling will move to the Trash, which the user confirms before it happens.
public struct UninstallConfirmation: Equatable, Sendable {
    /// Names of the apps to uninstall, in the order of the list. Empty when only leftovers
    /// are selected.
    public let appNames: [String]
    /// How many of the items are leftovers, such as caches and preferences, and not apps.
    public let leftoverCount: Int
    /// Space all the items take up.
    public let size: Int64

    public init(appNames: [String], leftoverCount: Int, size: Int64) {
        self.appNames = appNames
        self.leftoverCount = leftoverCount
        self.size = size
    }
}
