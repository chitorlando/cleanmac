import AppKit

extension DiskNode {
    /// Opens in Finder the folder that holds the item, with the item selected.
    @MainActor
    func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
