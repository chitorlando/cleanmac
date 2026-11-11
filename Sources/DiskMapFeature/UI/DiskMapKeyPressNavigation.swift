import SwiftUI

/// Keyboard navigation of the disk map where SwiftUI can read keys itself.
///
/// The map takes the keyboard focus as it appears, without a focus ring around it.
@available(macOS 14, *)
struct DiskMapKeyPressNavigation: ViewModifier {
    /// Carries out what a key press asked for.
    let perform: @MainActor (DiskMapKeyAction) -> Void

    @FocusState private var hasKeyboardFocus: Bool

    func body(content: Content) -> some View {
        content
            .focusable()
            .focused($hasKeyboardFocus)
            .focusEffectDisabled()
            .onAppear { hasKeyboardFocus = true }
            .onKeyPress(.downArrow) { perform(.moveHighlight(by: 1)); return .handled }
            .onKeyPress(.upArrow) { perform(.moveHighlight(by: -1)); return .handled }
            .onKeyPress(.rightArrow) { perform(.openHighlighted); return .handled }
            .onKeyPress(.return) { perform(.openHighlighted); return .handled }
            .onKeyPress(.leftArrow) { perform(.goUp); return .handled }
    }
}
