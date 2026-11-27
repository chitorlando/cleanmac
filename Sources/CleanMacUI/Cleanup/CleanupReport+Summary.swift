import CleanMacCore
import Foundation

extension CleanupReport {
    /// What the cleanup did, in a sentence: the items it moved to the Trash, whether it emptied
    /// the Trash, or that it couldn't. It never counts items when none were moved.
    var summary: String {
        if emptiedTrash {
            guard removedCount > 0 else {
                return String(
                    localized: "The Trash was emptied for good.",
                    bundle: .module,
                    comment: "Summary after a cleanup that emptied the Trash."
                )
            }
            return String(
                localized: "The Trash was emptied for good, then \(removedCount) items moved to it. Empty it again to reclaim their space.",
                bundle: .module,
                comment: "Summary after a cleanup that emptied the Trash and then moved other items to it. The argument is the number of items moved."
            )
        }
        if removedCount > 0 {
            return String(
                localized: "\(removedCount) items moved to the Trash. Empty it to reclaim the disk space.",
                bundle: .module,
                comment: "Summary after a cleanup. The argument is the number of items removed."
            )
        }
        if failures.includesTrashBins {
            return String(
                localized: "The Trash couldn’t be emptied, so nothing was erased.",
                bundle: .module,
                comment: "Summary after a cleanup that couldn’t empty the Trash and moved nothing to it."
            )
        }
        return String(
            localized: "Nothing was moved to the Trash.",
            bundle: .module,
            comment: "Summary after a cleanup that couldn’t move any item to the Trash."
        )
    }
}
