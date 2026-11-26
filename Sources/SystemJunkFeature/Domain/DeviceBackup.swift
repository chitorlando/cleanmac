import Foundation

/// An iPhone or iPad backup that Finder, or iTunes before it, keeps on this Mac.
public struct DeviceBackup: Hashable, Sendable {
    /// Identifies the device, which all its backups share.
    public let deviceID: String
    /// The name the user gave the device, such as “iPhone de Ana”.
    public let deviceName: String
    /// The model, such as “iPhone 15” or “iPhone15,4”, when the backup tells.
    public let model: String?
    public let lastBackupDate: Date?
    /// Whether it's the newest backup of its device, which the user most likely wants to keep.
    public let isLatest: Bool

    public init(deviceID: String, deviceName: String, model: String?, lastBackupDate: Date?, isLatest: Bool) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.model = model
        self.lastBackupDate = lastBackupDate
        self.isLatest = isLatest
    }
}

extension DeviceBackup {
    /// What the backup in `folder` says about itself in its `Info.plist`. A backup without one,
    /// such as one that didn't finish, is named after its folder and has no date.
    init(readingInfoIn folder: URL) {
        let info = (try? Data(contentsOf: folder.appending(path: "Info.plist")))
            .flatMap { try? PropertyListSerialization.propertyList(from: $0, format: nil) as? [String: Any] } ?? [:]
        let deviceID = (info["Unique Identifier"] as? String) ?? (info["Target Identifier"] as? String)
        self.init(
            deviceID: deviceID?.uppercased() ?? folder.lastPathComponent,
            deviceName: (info["Device Name"] as? String) ?? (info["Display Name"] as? String) ?? folder.lastPathComponent,
            model: (info["Product Name"] as? String) ?? (info["Product Type"] as? String),
            lastBackupDate: info["Last Backup Date"] as? Date,
            isLatest: false
        )
    }

    func marked(latest: Bool) -> DeviceBackup {
        DeviceBackup(deviceID: deviceID, deviceName: deviceName, model: model, lastBackupDate: lastBackupDate, isLatest: latest)
    }
}
