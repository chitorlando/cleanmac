import Darwin
import Foundation

/// Measures the user's Trash, bin by bin, without changing anything.
///
/// Only the user's own bins are looked at: the one in the home folder and, on each mounted
/// volume, the one macOS names after the user's ID. The bins of other users are never touched.
///
/// macOS keeps apps out of the Trash until they have Full Disk Access, which the bin in the
/// home folder tells. The bins on other volumes are only looked at with Full Disk Access:
/// without it, looking inside an external or network volume makes macOS ask the user whether
/// CleanMac may, and measuring must never bring up such a question.
public struct TrashSizeReader: Sendable {
    /// Files Finder keeps in a bin for itself, which don't make it hold anything.
    private static let finderFiles: Set<String> = [".DS_Store", ".localized"]

    private let home: URL
    private let volumes: URL
    private let userID: uid_t
    private let sizer: any SizeCalculating
    private let fullDiskAccess: any FullDiskAccessChecking

    /// - Parameters:
    ///   - home: The user's home folder, whose `.Trash` is the main bin.
    ///   - volumes: The folder where volumes are mounted.
    ///   - userID: The user whose bins are measured on the other volumes.
    public init(
        home: URL,
        volumes: URL = URL(filePath: "/Volumes", directoryHint: .isDirectory),
        userID: uid_t = getuid(),
        sizer: any SizeCalculating = AllocatedSizeCalculator(),
        fullDiskAccess: any FullDiskAccessChecking = ProtectedFileFullDiskAccessChecker()
    ) {
        self.home = home
        self.volumes = volumes
        self.userID = userID
        self.sizer = sizer
        self.fullDiskAccess = fullDiskAccess
    }

    /// The bins that hold something, or `.unreadable` when macOS keeps CleanMac out of the Trash.
    public func read() -> TrashUsage {
        let homeBin = TrashBin(url: home.appending(path: ".Trash", directoryHint: .isDirectory))
        guard let homeItems = items(in: homeBin) else { return .unreadable }

        var usages = [usage(of: homeBin, holding: homeItems)]
        if fullDiskAccess.hasFullDiskAccess() {
            usages += volumeBins().map { usage(of: $0, holding: items(in: $0) ?? []) }
        }
        return .readable(usages.filter { $0.size > 0 })
    }

    /// What the bin holds: nothing when there's no such bin, or `nil` when macOS keeps CleanMac out.
    private func items(in bin: TrashBin) -> [URL]? {
        do {
            return try FileManager.default.contentsOfDirectory(at: bin.url, includingPropertiesForKeys: nil)
                .filter { !Self.finderFiles.contains($0.lastPathComponent) }
        } catch where CleanupFailureClassifier.kind(of: error) == .protectedByMacOS {
            return nil
        } catch {
            return []
        }
    }

    private func usage(of bin: TrashBin, holding items: [URL]) -> TrashBinUsage {
        TrashBinUsage(bin: bin, size: items.reduce(0) { $0 + sizer.size(of: $1) })
    }

    /// The user's bin on each mounted volume, by name. Links are left out, such as the one to
    /// the startup disk, whose bin is the one in the home folder.
    private func volumeBins() -> [TrashBin] {
        let mounted = (try? FileManager.default.contentsOfDirectory(
            at: volumes,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: .skipsHiddenFiles
        )) ?? []
        return mounted
            .filter { (try? $0.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true }
            .map { volume in
                TrashBin(
                    url: volume.appending(path: ".Trashes/\(userID)", directoryHint: .isDirectory),
                    volumeName: volume.lastPathComponent
                )
            }
            .sorted { ($0.volumeName ?? "") < ($1.volumeName ?? "") }
    }
}
