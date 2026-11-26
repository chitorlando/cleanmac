import CleanMacCore
import Foundation

extension JunkItemDetail {
    /// What the review calls the item instead of its file name.
    var title: String {
        switch self {
        case .trashBin(let bin):
            guard let volume = bin.volumeName else {
                return String(
                    localized: "On This Mac",
                    bundle: .module,
                    comment: "Name of the Trash bin in the home folder, among the Trash bins of System Junk."
                )
            }
            return String(
                localized: "On \(volume)",
                bundle: .module,
                comment: "Name of the Trash bin of another volume, among the Trash bins of System Junk. The argument is the volume, such as “Backup Disk”."
            )
        }
    }
}
