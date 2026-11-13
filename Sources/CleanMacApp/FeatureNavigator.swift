import CleanMacUI
import Combine
import Foundation

/// Which feature the window shows, changed from the sidebar or by a feature that opens another.
@MainActor
final class FeatureNavigator: ObservableObject {
    @Published var selectedID: String?

    private let modules: [any FeatureModule]

    init(modules: [any FeatureModule], selectedID: String?) {
        self.modules = modules
        self.selectedID = selectedID
    }

    var selectedModule: (any FeatureModule)? {
        modules.first { $0.id == selectedID }
    }

    /// Shows the feature with `featureID`, and in it the item at `itemURL` when given.
    /// Keeps the current feature when no feature has that id.
    func open(_ featureID: String, showing itemURL: URL? = nil) {
        guard let module = modules.first(where: { $0.id == featureID }) else { return }
        selectedID = featureID
        if let itemURL {
            module.show(itemAt: itemURL)
        }
    }

    /// What the other features offer to do with the items the selected feature shows, in the
    /// order of the features. A feature's own actions are left out: the uninstaller's list
    /// shouldn't offer to open its apps in the uninstaller.
    var itemActions: [FeatureItemAction] {
        modules.filter { $0.id != selectedID }.flatMap { $0.itemActions }
    }

    /// The action features use to open each other.
    var openFeatureAction: OpenFeatureAction {
        OpenFeatureAction { [weak self] featureID, itemURL in self?.open(featureID, showing: itemURL) }
    }
}
