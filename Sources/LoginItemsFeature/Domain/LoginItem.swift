import CleanMacCore
import Foundation

/// A launchd property list that starts something at login, at startup or in the background.
public struct LoginItem: Identifiable, Hashable, Sendable {
    /// The property list itself, which is what gets moved to the Trash.
    public let item: CleanableItem
    public let job: LaunchJobDefinition
    public let scope: LaunchScope
    public let kind: LaunchItemKind
    /// The app it belongs to, when it could be found.
    public let owner: LoginItemOwner?
    /// Its program no longer exists, usually because the app that installed it was deleted.
    public let isOrphaned: Bool

    public var id: URL { item.url }
    public var plistURL: URL { item.url }

    /// The owner's name or, without one, the job's label.
    public var displayName: String { owner?.name ?? job.label }

    /// Only the user's own agents can be removed without an administrator.
    public var isRemovable: Bool { scope == .currentUser }

    public init(
        item: CleanableItem,
        job: LaunchJobDefinition,
        scope: LaunchScope,
        kind: LaunchItemKind,
        owner: LoginItemOwner?,
        isOrphaned: Bool
    ) {
        self.item = item
        self.job = job
        self.scope = scope
        self.kind = kind
        self.owner = owner
        self.isOrphaned = isOrphaned
    }
}
