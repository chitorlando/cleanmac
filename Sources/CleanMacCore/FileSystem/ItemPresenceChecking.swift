import Foundation

/// Tells whether an item is on disk, and says so when it can't tell.
public protocol ItemPresenceChecking: Sendable {
    func presence(of url: URL) -> ItemPresence
}
