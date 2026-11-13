import Foundation

public extension ItemMenuAction {
    /// Carries out the action on the item at `url`. Select and Deselect call `onToggle`,
    /// so the feature keeps its own selection rules.
    @MainActor
    func perform(
        on url: URL,
        files: any FileActionPerforming,
        openFeature: OpenFeatureAction,
        onToggle: () -> Void
    ) {
        switch self {
        case .open: files.open(url)
        case .select, .deselect: onToggle()
        case let .feature(action, target): openFeature(action.featureID, showing: target)
        case .showInFinder: files.showInFinder(url)
        case .copyPath: files.copyPath(of: url)
        }
    }
}
