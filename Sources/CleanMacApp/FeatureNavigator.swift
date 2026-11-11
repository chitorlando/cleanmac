import CleanMacUI
import Combine

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

    /// Shows the feature with `featureID`, or keeps the current one when no feature has that id.
    func open(_ featureID: String) {
        guard modules.contains(where: { $0.id == featureID }) else { return }
        selectedID = featureID
    }

    /// The action features use to open each other.
    var openFeatureAction: OpenFeatureAction {
        OpenFeatureAction { [weak self] featureID in self?.open(featureID) }
    }
}
