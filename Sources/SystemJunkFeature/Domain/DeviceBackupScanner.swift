import CleanMacCore
import Foundation

/// Offers the iPhone and iPad backups in `~/Library/Application Support/MobileSync/Backup`,
/// each named after its device and date, and the newest one of each device marked as such.
///
/// A backup may be the only copy of a device's data, so none is selected until the user picks
/// it, and removing it moves it to the Trash. Without Full Disk Access, macOS keeps CleanMac
/// out of the folder, and the category says so instead of showing it empty.
public struct DeviceBackupScanner: JunkScanner {
    private let folder: URL
    private let sizer: any SizeCalculating

    /// - Parameter folder: The folder that holds a folder per backup.
    public init(folder: URL, sizer: any SizeCalculating) {
        self.folder = folder
        self.sizer = sizer
    }

    public var category: JunkCategory { .deviceBackups }

    public func scan() async -> CategoryScanResult {
        let folders: [URL]
        do {
            folders = try FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            )
        } catch where CleanupFailureClassifier.kind(of: error) == .protectedByMacOS {
            return .unreadable(category)
        } catch {
            return CategoryScanResult(category: category, items: [])
        }

        let found = folders.filter(Self.isFolder).map { (url: $0, backup: DeviceBackup(readingInfoIn: $0)) }
        let newestDates = Self.newestDates(of: found.map { $0.backup })
        let backups = found
            .map { url, backup in
                let isLatest = backup.lastBackupDate != nil && backup.lastBackupDate == newestDates[backup.deviceID]
                return (item: CleanableItem(url: url, size: sizer.size(of: url)), backup: backup.marked(latest: isLatest))
            }
            .filter { $0.item.size > 0 }
            .sorted { Self.precedes($0.backup, $1.backup) }
        return CategoryScanResult(
            category: category,
            items: backups.map { $0.item },
            details: Dictionary(uniqueKeysWithValues: backups.map { ($0.item.id, JunkItemDetail.deviceBackup($0.backup)) })
        )
    }

    /// The date of the newest backup of each device, by device. Backups without a date don't count.
    private static func newestDates(of backups: [DeviceBackup]) -> [String: Date] {
        Dictionary(grouping: backups, by: \.deviceID).compactMapValues { $0.compactMap(\.lastBackupDate).max() }
    }

    /// Backups by device name, and each device's newest first.
    private static func precedes(_ first: DeviceBackup, _ second: DeviceBackup) -> Bool {
        if first.deviceName != second.deviceName {
            return first.deviceName.localizedStandardCompare(second.deviceName) == .orderedAscending
        }
        return (first.lastBackupDate ?? .distantPast) > (second.lastBackupDate ?? .distantPast)
    }

    private static func isFolder(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
    }
}
