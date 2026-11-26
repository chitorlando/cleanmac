import AppKit

/// An invisible view that tells which window holds it, and when that window is shown or
/// stops being shown.
///
/// A window is shown while it's ordered in and not minimized: not once it's closed or ordered
/// out, as a menu bar menu is when it closes, nor while its app is hidden. Other windows may
/// still cover it. Its occlusion state doesn't tell: macOS 13 never reports a menu bar menu as
/// visible.
final class WindowObservingView: NSView {
    private static let windowStateNotifications: [Notification.Name] = [
        NSWindow.didBecomeKeyNotification,
        NSWindow.didResignKeyNotification,
        NSWindow.didMiniaturizeNotification,
        NSWindow.didDeminiaturizeNotification,
        NSWindow.willCloseNotification
    ]

    /// Gets the window that holds the view each time it moves to another one, and `nil` once
    /// it leaves its window.
    var onWindowChange: (@MainActor (NSWindow?) -> Void)?
    /// Gets whether the window that holds the view is shown, each time that changes.
    var onVisibilityChange: (@MainActor (Bool) -> Void)?

    private weak var observedWindow: NSWindow?
    private var orderingObservation: NSKeyValueObservation?
    private var isWindowVisible = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window !== observedWindow else { return }
        stopObserving()
        if let window {
            observe(window)
        }
        onWindowChange?(window)
        updateVisibility()
    }

    /// Stops following the window, which then counts as no longer shown.
    func stopObserving() {
        guard let observedWindow else { return }
        for name in Self.windowStateNotifications {
            NotificationCenter.default.removeObserver(self, name: name, object: observedWindow)
        }
        orderingObservation?.invalidate()
        orderingObservation = nil
        self.observedWindow = nil
        updateVisibility()
    }

    private func observe(_ window: NSWindow) {
        observedWindow = window
        for name in Self.windowStateNotifications {
            NotificationCenter.default.addObserver(self, selector: #selector(windowStateDidChange(_:)), name: name, object: window)
        }
        // Ordering a window in or out posts no notification.
        orderingObservation = window.observe(\.isVisible) { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor in self.updateVisibility() }
        }
    }

    @objc private func windowStateDidChange(_ notification: Notification) {
        updateVisibility(isClosing: notification.name == NSWindow.willCloseNotification)
    }

    private func updateVisibility(isClosing: Bool = false) {
        let isVisible = !isClosing && (observedWindow.map { $0.isVisible && !$0.isMiniaturized } ?? false)
        guard isVisible != isWindowVisible else { return }
        isWindowVisible = isVisible
        onVisibilityChange?(isVisible)
    }
}
