import AppKit

/// An invisible view that tells which window holds it, and when that window comes on screen
/// or leaves it.
///
/// A window is on screen while it's ordered in and some of it can be seen: not when it's
/// closed or ordered out, as a menu bar menu is once it closes, nor when it's minimized,
/// its app is hidden or other windows cover it entirely.
final class WindowObservingView: NSView {
    private static let windowStateNotifications: [Notification.Name] = [
        NSWindow.didChangeOcclusionStateNotification,
        NSWindow.didBecomeKeyNotification,
        NSWindow.didResignKeyNotification,
        NSWindow.willCloseNotification
    ]

    /// Gets the window that holds the view each time it moves to another one, and `nil` once
    /// it leaves its window.
    var onWindowChange: (@MainActor (NSWindow?) -> Void)?
    /// Gets whether the window that holds the view is on screen, each time that changes.
    var onVisibilityChange: (@MainActor (Bool) -> Void)?

    private weak var observedWindow: NSWindow?
    private var isWindowVisible = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window !== observedWindow else { return }
        stopObserving()
        if let window {
            observedWindow = window
            for name in Self.windowStateNotifications {
                NotificationCenter.default.addObserver(self, selector: #selector(windowStateDidChange(_:)), name: name, object: window)
            }
        }
        onWindowChange?(window)
        updateVisibility()
    }

    /// Stops following the window, which then counts as off screen.
    func stopObserving() {
        guard let observedWindow else { return }
        for name in Self.windowStateNotifications {
            NotificationCenter.default.removeObserver(self, name: name, object: observedWindow)
        }
        self.observedWindow = nil
        updateVisibility()
    }

    @objc private func windowStateDidChange(_ notification: Notification) {
        updateVisibility(isClosing: notification.name == NSWindow.willCloseNotification)
    }

    private func updateVisibility(isClosing: Bool = false) {
        let isVisible = !isClosing && (observedWindow.map { $0.isVisible && $0.occlusionState.contains(.visible) } ?? false)
        guard isVisible != isWindowVisible else { return }
        isWindowVisible = isVisible
        onVisibilityChange?(isVisible)
    }
}
