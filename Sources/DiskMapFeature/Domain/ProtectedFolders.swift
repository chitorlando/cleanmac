import CleanMacCore
import Foundation

/// Folders that a scan stays out of until CleanMac has Full Disk Access.
///
/// macOS guards the containers where apps keep their data. Without Full Disk Access, looking
/// inside the container of another app makes macOS ask the user whether CleanMac may access
/// data from other apps, and it may ask again on the next scan. A scan must never bring up
/// such a prompt, so it leaves those folders out, and the map shows them as unreadable,
/// until the user grants access. Access is checked each time a scan starts, since it can be
/// granted at any moment.
public struct ProtectedFolders: Sendable {
    /// No folder: everything is walked.
    public static let none = ProtectedFolders([], fullDiskAccess: ProtectedFileFullDiskAccessChecker())

    private let folders: [URL]
    private let fullDiskAccess: any FullDiskAccessChecking

    public init(_ folders: [URL], fullDiskAccess: any FullDiskAccessChecking) {
        self.folders = folders
        self.fullDiskAccess = fullDiskAccess
    }

    /// The containers of `~/Library`, `Containers` and `Group Containers`, for the home folder `home`.
    public static func appContainers(in home: URL, fullDiskAccess: any FullDiskAccessChecking) -> ProtectedFolders {
        let library = home.appending(path: "Library", directoryHint: .isDirectory)
        return ProtectedFolders(
            [library.appending(path: "Containers"), library.appending(path: "Group Containers")],
            fullDiskAccess: fullDiskAccess
        )
    }

    /// The folders a scan must leave out now: those that exist, unless CleanMac has Full Disk Access.
    ///
    /// Telling whether a folder exists looks at the folder, not inside it, which macOS allows.
    func foldersToLeaveOut() -> [URL] {
        guard !folders.isEmpty, !fullDiskAccess.hasFullDiskAccess() else { return [] }
        return folders.filter { FileManager.default.fileExists(atPath: $0.path(percentEncoded: false)) }
    }
}
