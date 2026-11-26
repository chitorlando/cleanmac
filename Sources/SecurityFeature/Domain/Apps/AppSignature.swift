/// How far an app's signature can be trusted, from Apple's own down to a broken one.
public enum AppSignature: Hashable, Sendable {
    /// Signed by Apple, as macOS and Apple's apps are.
    case apple
    /// Signed by the App Store.
    case appStore
    /// Signed by an identified developer and checked by Apple for malware.
    case notarized
    /// Signed by an identified developer that Gatekeeper accepts without notarization,
    /// such as an app signed before Apple required it, or one the user allowed.
    case identifiedDeveloper
    /// Signed with a certificate from Apple, but Gatekeeper wouldn't let it open, usually
    /// because it isn't notarized or its certificate was revoked.
    case rejectedByGatekeeper
    /// Signed without a certificate from Apple, so nothing confirms who made it.
    case adHocOrSelfSigned
    case unsigned
    /// The code or its resources changed after it was signed.
    case damaged
    /// The signature couldn't be read.
    case unknown

    /// Whether the user should look at the app. Apps the review couldn't read aren't flagged.
    public var isRisky: Bool {
        switch self {
        case .rejectedByGatekeeper, .adHocOrSelfSigned, .unsigned, .damaged: true
        case .apple, .appStore, .notarized, .identifiedDeveloper, .unknown: false
        }
    }
}
