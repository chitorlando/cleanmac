import AppKit
import SwiftUI

public extension View {
    /// Calls `action` with the window that holds the view each time the view moves to another
    /// one, and with `nil` once it leaves its window.
    func onHostingWindowChange(perform action: @escaping @MainActor (NSWindow?) -> Void) -> some View {
        background(HostingWindowObserver(onWindowChange: action))
    }

    /// Calls `action` with whether the window that holds the view is on screen, each time that
    /// changes, and with `false` once the view leaves a window that was.
    ///
    /// Unlike appearing and disappearing, it also follows windows SwiftUI keeps while they're
    /// away, such as the one of a menu bar menu, which only orders out when it closes.
    func onWindowVisibilityChange(perform action: @escaping @MainActor (Bool) -> Void) -> some View {
        background(HostingWindowObserver(onVisibilityChange: action))
    }
}

/// Puts a `WindowObservingView` behind a SwiftUI view.
private struct HostingWindowObserver: NSViewRepresentable {
    var onWindowChange: (@MainActor (NSWindow?) -> Void)?
    var onVisibilityChange: (@MainActor (Bool) -> Void)?

    func makeNSView(context: Context) -> WindowObservingView {
        let view = WindowObservingView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ view: WindowObservingView, context: Context) {
        view.onWindowChange = onWindowChange
        view.onVisibilityChange = onVisibilityChange
    }

    static func dismantleNSView(_ view: WindowObservingView, coordinator: Void) {
        view.stopObserving()
    }
}
