import Foundation

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
