import Foundation

public extension ItemMenuAction {
    /// Carries out the action on the item at `url`. Select and Deselect call `onToggle`,
    /// so the feature keeps its own selection rules.
    @MainActor
    func perform(on url: URL, files: any FileActionPerforming, onToggle: () -> Void) {
        switch self {
        case .showInFinder: files.showInFinder(url)
        case .open: files.open(url)
        case .copyPath: files.copyPath(of: url)
        case .select, .deselect: onToggle()
        }
    }
}
