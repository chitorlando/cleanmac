import CleanMacUI
import SwiftUI

/// Lets the keyboard drive the disk map as soon as it appears: ↑ and ↓ move through the
/// items, → or Return opens a folder and ← goes up.
///
/// On a highlighted app, → and Return show it in the Uninstaller, as the note on its row
/// does, when the app shell says which feature that is.
///
/// SwiftUI reads the keys itself from macOS 14 on. Earlier systems get the same keys
/// through AppKit.
struct DiskMapKeyboardNavigation: ViewModifier {
    let viewModel: DiskMapViewModel

    @Environment(\.openFeature) private var openFeature
    @Environment(\.uninstallerFeatureID) private var uninstallerFeatureID

    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content.modifier(DiskMapKeyPressNavigation(perform: perform))
        } else {
            content.modifier(DiskMapKeyDownNavigation(perform: perform))
        }
    }

    /// Does what a key press asked for, in the map or in the feature the press is meant for.
    @MainActor
    private func perform(_ action: DiskMapKeyAction) {
        let highlighted = viewModel.highlightedItem
        let advice = highlighted.map { viewModel.advice(for: $0) }
        let router = DiskMapKeyRouter(uninstallerFeatureID: uninstallerFeatureID)
        switch router.route(for: action, highlighted: highlighted, advice: advice) {
        case .map:
            viewModel.perform(action)
        case .feature(let id, let itemURL):
            openFeature(id, showing: itemURL)
        }
    }
}
