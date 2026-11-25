import CleanMacCore
import CleanMacUI
import SwiftUI

/// Row of the Settings window with the folders that the scans of large files and of
/// duplicates leave out (see `ScanSettings.excludedFolders`).
///
/// It takes the folders those scans look in: inside the home folder, but not the home folder
/// itself, nor `~/Library`, a hidden folder or a package, which they always leave out. Each
/// one is kept the way the scans spell it, so the same folder reached another way, such as
/// through a symbolic link, is listed once.
struct ExcludedFolderList: View {
    let preferences: Preferences

    var body: some View {
        let scans = ScanScopePolicy.currentUserHome
        SettingFolderList(
            ScanSettings.excludedFolders,
            in: preferences,
            title: Text("Excluded folders", bundle: .module, comment: "Setting of the scans of large files and of duplicates: the folders they never look in. A list of folders follows."),
            note: Text("Large Files and Duplicates never look in these folders, or in your Library folder. Takes effect the next time you scan.", bundle: .module, comment: "Note under the setting of the folders that the scans of large files and of duplicates never look in."),
            emptyNote: Text("No folders are excluded.", bundle: .module, comment: "Shown in place of the list of excluded folders while it is empty."),
            refusalNote: Text("Only folders inside your home folder that these scans look in can be excluded.", bundle: .module, comment: "Shown under the list of excluded folders when some of the folders chosen can’t be added, such as the home folder itself or a folder outside it."),
            startingFolder: scans.home
        ) { folder in
            scans.scope(limitedTo: folder)?.folder
        }
    }
}
