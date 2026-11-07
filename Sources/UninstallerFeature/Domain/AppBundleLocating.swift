import Foundation

/// Finds the application bundles stored inside a set of folders.
public protocol AppBundleLocating: Sendable {
    func applications(in folders: [URL]) -> [URL]
}
