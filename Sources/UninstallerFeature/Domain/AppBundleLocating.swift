import Foundation

/// Finds the application bundles stored inside a set of folders.
public protocol AppBundleLocating: Sendable {
    func applications(in folders: [URL]) -> [URL]

    /// The app at `url`, wherever it is, or `nil` when there is no app there that the user can remove.
    func application(at url: URL) -> URL?
}
