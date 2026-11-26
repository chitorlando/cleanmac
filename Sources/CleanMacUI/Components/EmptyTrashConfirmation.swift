import SwiftUI

/// Dialog that asks before emptying the Trash, which erases what it holds for good.
///
/// It's the sibling of `trashConfirmation`, for the one cleanup that can't be undone. Its
/// wording says that nothing erased can be put back, and Cancel is the default button: Return
/// closes the dialog without erasing anything, and only clicking the destructive button empties
/// the Trash. Cancel and Escape close it without removing anything.
struct EmptyTrashConfirmation: ViewModifier {
    let text: EmptyTrashConfirmationText
    let isPresented: Bool
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            Text(verbatim: text.title),
            isPresented: .dialog(isPresented: isPresented, onDismiss: onDismiss)
        ) {
            Button(role: .destructive, action: onConfirm) {
                Text(verbatim: text.confirmTitle)
            }
            Button(role: .cancel) {} label: {
                Text("Cancel", bundle: .module, comment: "Button that closes the dialog that asks before emptying the Trash, without erasing anything.")
            }
            .keyboardShortcut(.defaultAction)
        } message: {
            Text(verbatim: text.message)
        }
    }
}

public extension View {
    /// Asks before emptying the Trash, which holds `trashSize` bytes, while `isPresented` is true.
    /// When the cleanup then moves `itemsToMove` items that take up `sizeToMove` bytes to the
    /// Trash, it asks about both.
    ///
    /// - Parameters:
    ///   - onConfirm: Empties the Trash, and then moves the items to it.
    ///   - onDismiss: Stops asking. Called whenever the dialog closes, after `onConfirm` too,
    ///     in an order SwiftUI decides, so `onConfirm` mustn't depend on it.
    func emptyTrashConfirmation(
        trashSize: Int64,
        itemsToMove: Int = 0,
        sizeToMove: Int64 = 0,
        isPresented: Bool,
        onConfirm: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(EmptyTrashConfirmation(
            text: EmptyTrashConfirmationText(trashSize: trashSize, itemsToMove: itemsToMove, sizeToMove: sizeToMove),
            isPresented: isPresented,
            onConfirm: onConfirm,
            onDismiss: onDismiss
        ))
    }
}
