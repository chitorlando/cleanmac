import SwiftUI

/// Dialog that asks before moving items to the Trash.
///
/// The button that removes them presents it instead of removing anything, so neither a
/// click nor Return, which presses that button, moves a file at once. In the dialog, Move to
/// Trash keeps the place of the default button: what goes to the Trash can be put back.
/// Cancel and Escape close it without removing anything.
struct TrashConfirmation: ViewModifier {
    let title: Text
    let isPresented: Bool
    let message: Text
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(title, isPresented: .dialog(isPresented: isPresented, onDismiss: onDismiss)) {
            Button(role: .destructive, action: onConfirm) {
                Text("Move to Trash", bundle: .module, comment: "Button that confirms moving the selected items to the Trash.")
            }
        } message: {
            message
        }
    }
}

extension Binding where Value == Bool {
    /// Presents a dialog while `isPresented` is true. The dialog closes itself, after any of its
    /// buttons or Escape, and only reports it to `onDismiss`.
    static func dialog(isPresented: Bool, onDismiss: @escaping () -> Void) -> Binding<Bool> {
        Binding(
            get: { isPresented },
            set: { isPresented in
                if !isPresented {
                    onDismiss()
                }
            }
        )
    }
}

public extension View {
    /// Asks before moving items to the Trash, while `isPresented` is true.
    ///
    /// - Parameters:
    ///   - title: The question, such as “Uninstall Zoom?”.
    ///   - message: What goes to the Trash, and that it can be put back from there.
    ///   - onConfirm: Moves the items to the Trash.
    ///   - onDismiss: Stops asking. Called whenever the dialog closes, after `onConfirm` too,
    ///     in an order SwiftUI decides, so `onConfirm` mustn't depend on it.
    func trashConfirmation(
        _ title: Text,
        isPresented: Bool,
        message: Text,
        onConfirm: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(TrashConfirmation(
            title: title,
            isPresented: isPresented,
            message: message,
            onConfirm: onConfirm,
            onDismiss: onDismiss
        ))
    }

    /// Asks before moving `itemCount` items that take up `size` bytes to the Trash.
    ///
    /// See `trashConfirmation(_:isPresented:message:onConfirm:onDismiss:)`.
    func trashConfirmation(
        itemCount: Int,
        size: Int64,
        isPresented: Bool,
        onConfirm: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        trashConfirmation(
            Text(
                "Move \(itemCount) items to the Trash?",
                bundle: .module,
                comment: "Title of the dialog that asks before moving items to the Trash. The argument is the number of items."
            ),
            isPresented: isPresented,
            message: Text(
                "They take up \(size.formattedByteCount). You can put them back from the Trash.",
                bundle: .module,
                comment: "Message of the dialog that asks before moving items to the Trash. The argument is a size, such as “1.2 GB”."
            ),
            onConfirm: onConfirm,
            onDismiss: onDismiss
        )
    }
}
