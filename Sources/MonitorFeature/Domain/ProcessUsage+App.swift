import Foundation

public extension ProcessUsage {
    /// The app bundle the process belongs to, or `nil` for a process that isn't part of an app,
    /// whose icon comes from a bare executable or is unknown.
    var appURL: URL? {
        guard let iconURL, iconURL.pathExtension.lowercased() == "app" else { return nil }
        return iconURL
    }
}
