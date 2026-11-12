import AppKit

/// `FileActionPerforming` with the Finder, the item's default app and the general pasteboard.
public struct WorkspaceFileActions: FileActionPerforming {
    public init() {}

    @MainActor
    public func showInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @MainActor
    public func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    @MainActor
    public func copyPath(of url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
}
