import SwiftUI

/// Keyboard navigation of the disk map before macOS 14, where SwiftUI can't read keys and
/// can't hide the focus ring of a focusable view.
///
/// An AppKit view behind the map takes the keyboard as the map appears and asks
/// `DiskMapKeyBindings` what each key does.
struct DiskMapKeyDownNavigation: ViewModifier {
    /// Carries out what a key press asked for.
    let perform: @MainActor (DiskMapKeyAction) -> Void

    private let bindings = DiskMapKeyBindings()

    func body(content: Content) -> some View {
        content.background(KeyCatcher(onKeyDown: handleKeyDown))
    }

    @MainActor
    private func handleKeyDown(_ keyCode: UInt16) -> Bool {
        guard
            let key = DiskMapKey(keyCode: keyCode),
            let action = bindings.action(for: key)
        else { return false }
        perform(action)
        return true
    }
}
