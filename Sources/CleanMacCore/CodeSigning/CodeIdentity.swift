import Foundation

/// Who signed some code and the hashes that tell it from any other code, as its signature
/// declares them.
public struct CodeIdentity: Hashable, Sendable {
    /// The Team ID of the developer, such as “ABCDE12345”. `nil` when the signature names none,
    /// as Apple's own code and ad hoc signatures don't.
    public let teamID: String?
    /// The cdhashes: the hash of each code directory of the signature, one per digest algorithm,
    /// such as SHA-1 and SHA-256, cut to 20 bytes. The first is the one macOS identifies the code
    /// by, which `codesign --display` shows as `CDHash`.
    public let cdHashes: [Data]

    public init(teamID: String?, cdHashes: [Data]) {
        self.teamID = teamID
        self.cdHashes = cdHashes
    }
}

/// Reads who signed some code and which code it is from its signature, without checking that the
/// code still matches it, which takes far longer: a whole app's resources are read for that.
public protocol CodeIdentityReading: Sendable {
    /// `nil` when the code isn't signed or can't be read.
    func identity(ofCodeAt url: URL) -> CodeIdentity?
}
