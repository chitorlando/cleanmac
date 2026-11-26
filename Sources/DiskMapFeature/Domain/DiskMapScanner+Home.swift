import CleanMacCore
import Foundation

public extension DiskMapScanner {
    /// Map of the current user's home folder, `~/Library` and hidden items included.
    ///
    /// The other features leave `~/Library` and hidden items out because what's inside belongs
    /// to apps, tools and macOS. The map walks them anyway: `~/Library` is often the largest
    /// folder of the home, with caches, developer tools, device backups and app data, and
    /// hidden folders such as `~/.Trash`, or the caches of developer tools, can be large too.
    /// Leaving them out would hide where much of the space goes and make the total disagree
    /// with the disk. Measuring them is harmless; removing things from them is not, so that's
    /// for the screens to guard.
    ///
    /// Without Full Disk Access, the containers of `~/Library` are left out, as macOS would ask
    /// the user about them (see `ProtectedFolders`), and so is whatever macOS keeps private,
    /// such as Mail or Messages. The map shows those folders as unreadable.
    static func home(
        fullDiskAccess: any FullDiskAccessChecking = ProtectedFileFullDiskAccessChecker()
    ) -> DiskMapScanner {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return DiskMapScanner(
            root: home,
            protectedFolders: .appContainers(in: home, fullDiskAccess: fullDiskAccess),
            makeWalker: { DiskMapScanner.walker(leavingOut: $0) }
        )
    }

    /// The walker of the map: hidden items included, packages measured whole as single items,
    /// symbolic links never followed and the `leftOut` folders skipped with what's inside.
    /// Files only in the cloud are never downloaded and count for the space they take up on
    /// this Mac.
    static func walker(leavingOut leftOut: [URL] = []) -> any FileWalking {
        FileSystemWalker(
            excludedDirectories: leftOut,
            packageSizeCalculator: AllocatedSizeCalculator(),
            includesHiddenItems: true
        )
    }
}
