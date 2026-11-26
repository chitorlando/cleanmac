import Foundation

/// What the dialog that asks before emptying the Trash says.
///
/// Emptying the Trash erases everything in it for good, not only what CleanMac measured, so
/// the dialog says so. When the same cleanup then moves other items to the Trash, it says
/// that too, and that those can still be put back.
public struct EmptyTrashConfirmationText: Equatable, Sendable {
    public let title: String
    public let message: String
    /// Title of the button that empties the Trash.
    public let confirmTitle: String

    /// - Parameters:
    ///   - trashSize: What the Trash holds, as CleanMac measured it, or `nil` when it couldn't,
    ///     such as without Full Disk Access.
    ///   - itemsToMove: How many items the cleanup moves to the Trash once it's empty.
    ///   - sizeToMove: What those items take up.
    public init(trashSize: Int64?, itemsToMove: Int = 0, sizeToMove: Int64 = 0) {
        let erasing = trashSize.map { trashSize in
            String(
                localized: "Everything in the Trash, \(trashSize.formattedByteCount), is erased for good. You can’t undo this.",
                bundle: .module,
                comment: "Message of the dialog that asks before emptying the Trash. The argument is a size, such as “1.2 GB”."
            )
        } ?? String(
            localized: "Everything in the Trash is erased for good. You can’t undo this.",
            bundle: .module,
            comment: "Message of the dialog that asks before emptying the Trash, when CleanMac couldn’t measure it."
        )
        guard itemsToMove > 0 else {
            title = String(
                localized: "Empty the Trash?",
                bundle: .module,
                comment: "Title of the dialog that asks before emptying the Trash."
            )
            message = erasing
            confirmTitle = String(
                localized: "Empty Trash",
                bundle: .module,
                comment: "Button that confirms emptying the Trash, which erases what it holds for good."
            )
            return
        }
        title = String(
            localized: "Empty the Trash and move \(itemsToMove) items to it?",
            bundle: .module,
            comment: "Title of the dialog that asks before emptying the Trash and then moving other items to it. The argument is the number of items moved."
        )
        let moving = String(
            localized: "Then the other items, which take up \(sizeToMove.formattedByteCount), go to the Trash, where you can put them back.",
            bundle: .module,
            comment: "Second part of the message of the dialog that asks before emptying the Trash and then moving other items to it. The argument is a size, such as “1.2 GB”."
        )
        message = "\(erasing) \(moving)"
        confirmTitle = String(
            localized: "Empty Trash and Move Items",
            bundle: .module,
            comment: "Button that confirms emptying the Trash, which erases what it holds for good, and then moving other items to it."
        )
    }
}
