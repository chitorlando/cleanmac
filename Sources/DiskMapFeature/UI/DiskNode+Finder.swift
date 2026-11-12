import AppKit

extension DiskNode {
    /// Opens in Finder the folder that holds the item, with the item selected.
    @MainActor
    func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    /// Puts the item's path on the clipboard, in place of what was there.
    @MainActor
    func copyPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
}
