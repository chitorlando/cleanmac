import CleanMacCore
import Foundation

/// Finds the app a launchd job belongs to and whether its program still exists.
public struct LoginItemAttributor: Sendable {
    private static let appExtension = "app"
    /// Shorter identifiers, such as "com.example", name a vendor rather than an app.
    private static let minimumBundleIDComponents = 2

    private let appLocator: any AppLocating
    private let reader: any DirectoryReading
    private let presence: any ItemPresenceChecking

    /// - Parameter presence: Tells a program that is gone from one that can't be reached.
    public init(
        appLocator: any AppLocating,
        reader: any DirectoryReading,
        presence: any ItemPresenceChecking = FileSystemItemPresenceChecker()
    ) {
        self.appLocator = appLocator
        self.reader = reader
        self.presence = presence
    }

    /// The app whose bundle contains the program or, failing that, an installed app whose
    /// bundle identifier is the label or starts it, as "com.example.app" does for
    /// "com.example.app.agent". The most specific identifier wins.
    public func owner(of job: LaunchJobDefinition) -> LoginItemOwner? {
        let appURL = job.programURL.flatMap(enclosingApp(of:)) ?? installedApp(matching: job.label)
        return appURL.map { LoginItemOwner(appURL: $0, name: $0.deletingPathExtension().lastPathComponent) }
    }

    /// Whether the program the job runs is known to be missing. A job without an absolute
    /// program path, or whose program can't be reached, such as a helper in a folder only root
    /// can enter, can't be checked, so it never counts as orphaned.
    public func isOrphaned(_ job: LaunchJobDefinition) -> Bool {
        guard let programURL = job.programURL else { return false }
        return presence.presence(of: programURL) == .missing
    }

    /// The outermost ".app" bundle in the program's path, such as the app that embeds a helper.
    private func enclosingApp(of programURL: URL) -> URL? {
        var appURL: URL?
        var url = URL(filePath: "/")
        for component in programURL.pathComponents.dropFirst() {
            url.append(path: component)
            if (component as NSString).pathExtension.lowercased() == Self.appExtension {
                appURL = url
                break
            }
        }
        guard let appURL, reader.itemExists(at: appURL) else { return nil }
        return appURL
    }

    private func installedApp(matching label: String) -> URL? {
        var components = label.split(separator: ".").map(String.init)
        while components.count >= Self.minimumBundleIDComponents {
            if let url = appLocator.appURL(forBundleID: components.joined(separator: ".")),
               reader.itemExists(at: url) {
                return url
            }
            components.removeLast()
        }
        return nil
    }
}
