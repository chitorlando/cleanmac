import AppKit

/// An invisible view that takes the keyboard as it enters a window and offers each key
/// press to a handler.
///
/// It stands in, before macOS 14, for a focused SwiftUI view that reads keys with
/// `onKeyPress`. Being the window's first responder is what makes it behave like one: it
/// only hears keys while its window is the key one, so not under a dialog, and not while a
/// text field or a list has the keyboard instead. A press the handler doesn't use goes on
/// to the next responder, so key equivalents such as the default button's Return still work.
final class KeyCatchingView: NSView {
    /// Gets the virtual key code of each press and returns whether it used it.
    var onKeyDown: @MainActor (UInt16) -> Bool = { _ in false }

    override var acceptsFirstResponder: Bool { true }

    /// The view draws nothing, and must not get a focus ring either.
    override var focusRingType: NSFocusRingType {
        get { .none }
        set {}
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
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
}
