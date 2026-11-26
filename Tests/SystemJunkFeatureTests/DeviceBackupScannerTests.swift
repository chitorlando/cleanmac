import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

struct DeviceBackupScannerTests {
    private let backupsPath = "MobileSync/Backup"
    private let march12 = Date(timeIntervalSince1970: 1_773_316_800)
    private let january5 = Date(timeIntervalSince1970: 1_767_571_200)
    private let february20 = Date(timeIntervalSince1970: 1_771_545_600)

    private func scanner(in folder: TemporaryFolder) -> DeviceBackupScanner {
        DeviceBackupScanner(folder: folder.root.appending(path: backupsPath), sizer: UniformSizeCalculator(bytes: 48_000))
    }

    /// Writes a backup the way Finder does: a folder with an `Info.plist` and the copied data.
    private func writeBackup(
        _ name: String,
        device: String,
        deviceName: String,
        productType: String,
        date: Date,
        in folder: TemporaryFolder
    ) throws {
        try folder.writePlist([
            "Unique Identifier": device,
            "Target Identifier": device,
            "Device Name": deviceName,
            "Display Name": deviceName,
            "Product Type": productType,
            "Last Backup Date": date
        ], to: "\(backupsPath)/\(name)/Info.plist")
        try folder.makeFile("\(backupsPath)/\(name)/Manifest.db")
    }

    private func backups(in result: CategoryScanResult) -> [DeviceBackup] {
        result.items.compactMap { item in
            guard case .deviceBackup(let backup) = result.detail(of: item) else { return nil }
            return backup
        }
    }

    @Test func readsEachBackupFromItsInfoPlistAndMarksTheNewestOfEachDevice() async throws {
        let folder = try TemporaryFolder()
        try writeBackup("00008110-AAA", device: "00008110-AAA", deviceName: "iPhone de Ana", productType: "iPhone14,5", date: march12, in: folder)
        try writeBackup("00008110-AAA-20260105-101112", device: "00008110-AAA", deviceName: "iPhone de Ana", productType: "iPhone14,5", date: january5, in: folder)
        try writeBackup("00008027-BBB", device: "00008027-BBB", deviceName: "iPad de Luis", productType: "iPad8,1", date: february20, in: folder)

        let result = await scanner(in: folder).scan()

        #expect(result.category == .deviceBackups)
        #expect(!result.needsFullDiskAccess)
        #expect(result.items.map(\.name) == ["00008027-BBB", "00008110-AAA", "00008110-AAA-20260105-101112"])
        #expect(result.items.allSatisfy { $0.size == 48_000 })
        #expect(backups(in: result) == [
            DeviceBackup(deviceID: "00008027-BBB", deviceName: "iPad de Luis", model: "iPad8,1", lastBackupDate: february20, isLatest: true),
            DeviceBackup(deviceID: "00008110-AAA", deviceName: "iPhone de Ana", model: "iPhone14,5", lastBackupDate: march12, isLatest: true),
            DeviceBackup(deviceID: "00008110-AAA", deviceName: "iPhone de Ana", model: "iPhone14,5", lastBackupDate: january5, isLatest: false)
        ])
    }

    @Test func namesABackupWithoutInfoAfterItsFolderAndNeverMarksIt() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("\(backupsPath)/00008110-CCC/Manifest.db")

        let result = await scanner(in: folder).scan()

        #expect(backups(in: result) == [
            DeviceBackup(deviceID: "00008110-CCC", deviceName: "00008110-CCC", model: nil, lastBackupDate: nil, isLatest: false)
        ])
    }

    @Test func waitsForTheUserToPickABackupAndMovesItToTheTrash() {
        #expect(!JunkCategory.deviceBackups.preselectsItems)
        #expect(JunkCategory.deviceBackups.removal == .moveToTrash)
    }

    @Test func saysWhenMacOSKeepsCleanMacOutOfTheBackups() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("\(backupsPath)/00008110-AAA/Manifest.db")
        try folder.setPermissions(backupsPath, to: 0)
        defer { _ = try? folder.setPermissions(backupsPath, to: 0o755) }

        let result = await scanner(in: folder).scan()

        #expect(result.needsFullDiskAccess)
        #expect(result.items.isEmpty)
    }

    @Test func findsNothingWithoutBackups() async throws {
        let folder = try TemporaryFolder()

        let result = await scanner(in: folder).scan()

        #expect(!result.needsFullDiskAccess)
        #expect(result.items.isEmpty)
    }
}
