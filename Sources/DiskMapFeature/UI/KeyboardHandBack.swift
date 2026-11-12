/// Decides whether a click gives the keyboard back to the content it landed on.
///
/// From macOS 14 on, SwiftUI focuses a focusable view when it's clicked. Before that, the
/// view that catches the keys has to take the keyboard back itself, for instance after the
/// sidebar got it. It must not take it from someone who is typing, nor reach for it while a
/// sheet, such as a confirmation dialog, covers the window.
struct KeyboardHandBack: Equatable, Sendable {
    /// Whether the click landed inside the content.
    var isInsideContent: Bool
    /// Whether a sheet is attached to the content's window.
    var isUnderSheet: Bool
    /// Whether text is being edited in the content's window.
    var isEditingText: Bool

    var givesKeyboardToContent: Bool {
        isInsideContent && !isUnderSheet && !isEditingText
    }
}
