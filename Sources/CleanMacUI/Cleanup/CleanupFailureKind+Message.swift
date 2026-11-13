import CleanMacCore
import SwiftUI

extension CleanupFailureKind {
    /// What happened and what the user can do, instead of the system's technical text.
    var message: Text {
        switch self {
        case .protectedByMacOS:
            Text(
                "macOS protects this item. Move it to the Trash yourself in Finder, or give CleanMac Full Disk Access and try again.",
                bundle: .module,
                comment: "Why an item couldn't be moved to the Trash: macOS protects it, such as another app's container."
            )
        case .inUse:
            Text(
                "Another app is using it. Quit that app and try again.",
                bundle: .module,
                comment: "Why an item couldn't be moved to the Trash: it's open in another app."
            )
        case .missing:
            Text("It was no longer there.", bundle: .module, comment: "Why an item couldn't be moved to the Trash: it had already been removed.")
        case .unknown:
            Text("It couldn’t be moved to the Trash.", bundle: .module, comment: "Why an item couldn't be moved to the Trash, when the reason isn't known.")
        }
    }
}
