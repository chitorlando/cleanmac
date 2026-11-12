import Foundation

/// Carries out the context menu actions that act on the file itself.
public protocol FileActionPerforming: Sendable {
    @MainActor func showInFinder(_ url: URL)
    @MainActor func open(_ url: URL)
    @MainActor func copyPath(of url: URL)
}
