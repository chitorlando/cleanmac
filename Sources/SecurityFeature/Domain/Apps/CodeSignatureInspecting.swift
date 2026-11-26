import Foundation

/// Reads the code signature of an app bundle or a program on disk.
public protocol CodeSignatureInspecting: Sendable {
    func facts(forCodeAt url: URL) -> SignatureFacts
}

/// Whether Gatekeeper would let an app open.
public enum GatekeeperVerdict: Hashable, Sendable {
    case accepted
    case rejected
    /// Gatekeeper couldn't be asked, or couldn't assess the app.
    case unavailable
}

/// Asks Gatekeeper about an app, as `spctl --assess --type execute` does.
public protocol GatekeeperAssessing: Sendable {
    func verdict(forAppAt url: URL) -> GatekeeperVerdict
}
