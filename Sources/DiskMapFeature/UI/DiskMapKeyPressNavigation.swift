import SwiftUI

/// Keyboard navigation of the disk map where SwiftUI can read keys itself.
///
/// The map takes the keyboard focus as it appears, without a focus ring around it.
@available(macOS 14, *)
struct DiskMapKeyPressNavigation: ViewModifier {
    let viewModel: DiskMapViewModel

    @FocusState private var hasKeyboardFocus: Bool

    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($hasKeyboardFocus)
            .focusEffectDisabled()
            .onAppear { hasKeyboardFocus = true }
            .onKeyPress(.downArrow) { viewModel.moveHighlight(by: 1); return .handled }
            .onKeyPress(.upArrow) { viewModel.moveHighlight(by: -1); return .handled }
            .onKeyPress(.rightArrow) { viewModel.openHighlighted(); return .handled }
            .onKeyPress(.return) { viewModel.openHighlighted(); return .handled }
            .onKeyPress(.leftArrow) { viewModel.goUp(); return .handled }
    }
}
