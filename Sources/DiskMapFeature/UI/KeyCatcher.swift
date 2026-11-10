import SwiftUI

/// Puts a `KeyCatchingView` in a SwiftUI hierarchy, meant to sit behind the content whose
/// keys it handles.
struct KeyCatcher: NSViewRepresentable {
    /// Gets the virtual key code of each press and returns whether it used it.
    let onKeyDown: @MainActor (UInt16) -> Bool

    func makeNSView(context: Context) -> KeyCatchingView {
        let view = KeyCatchingView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ view: KeyCatchingView, context: Context) {
        view.onKeyDown = onKeyDown
    }
}
