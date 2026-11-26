import CleanMacCore
import Foundation

/// Why a login or background item deserves a look.
public enum PersistenceConcern: Hashable, Sendable {
    /// The program it starts has no code signature.
    case unsignedProgram
    /// The program it starts no longer matches its code signature.
    case damagedProgram
    /// It runs something from a temporary or shared folder, where any app or user can write,
    /// such as `/tmp` or `/Users/Shared`.
    case temporaryOrSharedFolder
    /// It runs something from a hidden folder, such as `~/.config`.
    case hiddenFolder
}

/// A launchd item that deserves a look, with what the review found about it.
public struct PersistenceFinding: Identifiable, Hashable, Sendable {
    /// The property list that tells launchd to start it.
    public let plistURL: URL
    public let job: LaunchJobDefinition
    public let kind: LaunchItemKind
    public let scope: LaunchScope
    /// The app it belongs to, when it could be found.
    public let owner: LoginItemOwner?
    /// What makes it worth a look, at least one: the program's signature first, then where it is.
    public let concerns: [PersistenceConcern]

    public init(
        plistURL: URL,
        job: LaunchJobDefinition,
        kind: LaunchItemKind,
        scope: LaunchScope,
        owner: LoginItemOwner?,
        concerns: [PersistenceConcern]
    ) {
        self.plistURL = plistURL
        self.job = job
        self.kind = kind
        self.scope = scope
        self.owner = owner
        self.concerns = concerns
    }

    public var id: URL { plistURL }

    /// The owner's name or, without one, the job's label.
    public var displayName: String { owner?.name ?? job.label }
}
