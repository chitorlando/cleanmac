import CleanMacCore
import SwiftUI

extension CleanupFailure {
    /// What happened and what the user can do, in words that fit what failed: moving an item
    /// to the Trash, or emptying a Trash bin.
    var message: Text {
        guard isTrashBin else { return kind.message }
        switch kind {
        case .protectedByMacOS:
            return Text(
                "macOS protects something in it. Empty the Trash yourself in Finder.",
                bundle: .module,
                comment: "Why a Trash bin couldn't be emptied: macOS protects something in it."
            )
        case .unknown:
            return Text("It couldn’t be emptied.", bundle: .module, comment: "Why a Trash bin couldn't be emptied, when the reason isn't known.")
        case .finderAutomationDenied, .inUse, .missing:
            return kind.message
        }
    }
}
