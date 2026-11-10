import CleanMacCore
import Foundation

public extension DiskMapScanner {
    /// Map of the current user's home folder, `~/Library` included.
    ///
    /// The other features leave `~/Library` out because what's inside belongs to apps and to
    /// macOS. The map walks it anyway: it's often the largest folder of the home, with caches,
    /// developer tools, device backups and app data, and leaving it out would hide where much
    /// of the space goes and make the total disagree with Finder. Measuring it is harmless;
    /// removing things from it is not, so that's for the screens to guard.
    ///
    /// Packages count as single items with their whole size, and hidden items are skipped.
    static func home() -> DiskMapScanner {
        DiskMapScanner(
            root: FileManager.default.homeDirectoryForCurrentUser,
            walker: FileSystemWalker(excludedDirectories: [], packageSizeCalculator: AllocatedSizeCalculator())
        )
    }
}
