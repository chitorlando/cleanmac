import AppKit

/// An invisible view that takes the keyboard as it enters a window and offers each key
/// press to a handler.
///
/// It stands in, before macOS 14, for a focused SwiftUI view that reads keys with
/// `onKeyPress`. Being the window's first responder is what makes it behave like one: it
/// only hears keys while its window is the key one, so not under a dialog, and not while a
/// text field or a list has the keyboard instead. A press the handler doesn't use goes on
/// to the next responder, so key equivalents such as the default button's Return still work.
///
/// Like a focusable view, it gets the keyboard back when the content in front of it is
/// clicked. SwiftUI handles most of those clicks without the view ever seeing them, so it
/// watches the window's clicks while it's in one.
final class KeyCatchingView: NSView {
    /// Gets the virtual key code of each press and returns whether it used it.
    var onKeyDown: @MainActor (UInt16) -> Bool = { _ in false }

    private var clickMonitor: Any?

    override var acceptsFirstResponder: Bool { true }

    /// The view draws nothing, and must not get a focus ring either.
    override var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopWatchingClicks()
        guard window != nil else { return }
        watchClicks()
        // AppKit calls this while SwiftUI is still placing its views. Taking the keyboard
        // from one of them right now would change its focus in the middle of that update,
        // so it waits for the next turn of the main loop.
        Task { @MainActor [weak self] in
            self?.takeKeyboard()
        }
    }

    override func keyDown(with event: NSEvent) {
        if !onKeyDown(event.keyCode) {
            super.keyDown(with: event)
        }
    }

    private func takeKeyboard() {
        guard let window, window.firstResponder !== self else { return }
        window.makeFirstResponder(self)
    }

    /// The monitor only looks: every click goes on unchanged, and the keyboard moves on the
    /// next turn of the main loop, once the click has done what it does. By then a dialog
    /// the click opened, or a text field it started editing, is already in place.
    private func watchClicks() {
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            let location = event.locationInWindow
            let windowNumber = event.windowNumber
            Task { @MainActor [weak self] in
                self?.takeKeyboardAfterClick(at: location, inWindowNumbered: windowNumber)
            }
            return event
        }
    }

    private func stopWatchingClicks() {
        guard let clickMonitor else { return }
        NSEvent.removeMonitor(clickMonitor)
        self.clickMonitor = nil
    }

    private func takeKeyboardAfterClick(at location: NSPoint, inWindowNumbered windowNumber: Int) {
        guard let window, window.windowNumber == windowNumber else { return }
        let handBack = KeyboardHandBack(
            isInsideContent: bounds.contains(convert(location, from: nil)),
            isUnderSheet: window.attachedSheet != nil,
            isEditingText: window.firstResponder is NSText
        )
        if handBack.givesKeyboardToContent {
            takeKeyboard()
        }
    }
}
