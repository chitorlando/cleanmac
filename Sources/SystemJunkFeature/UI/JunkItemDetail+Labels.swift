import CleanMacCore
import SwiftUI

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
        case .deviceBackup(let backup):
            // Such as “iPhone de Ana — 12 Mar 2026”.
            let date = backup.lastBackupDate?.formatted(date: .abbreviated, time: .omitted)
            return [backup.deviceName, date].compactMap { $0 }.joined(separator: " — ")
        }
    }

    /// What the review shows below the title instead of the item's folder, if anything.
    var subtitle: String? {
        guard case .deviceBackup(let backup) = self else { return nil }
        return backup.model
    }

    /// A short label next to the title, if any.
    var badge: Text? {
        guard case .deviceBackup(let backup) = self, backup.isLatest else { return nil }
        return Text("Most Recent", bundle: .module, comment: "Badge on the newest backup of a device, among the iPhone and iPad backups of System Junk.")
    }
}
