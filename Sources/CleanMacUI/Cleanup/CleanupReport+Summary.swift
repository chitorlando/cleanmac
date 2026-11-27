import CleanMacCore
import Foundation

extension CleanupReport {
    /// What the cleanup did, in a sentence: the items it moved to the Trash, and whether it
    /// emptied the Trash.
    var summary: String {
        guard emptiedTrash else {
            return String(
                localized: "\(removedCount) items moved to the Trash. Empty it to reclaim the disk space.",
                bundle: .module,
                comment: "Summary after a cleanup. The argument is the number of items removed."
            )
        }
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
}
