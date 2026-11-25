import CleanMacCore
import CleanMacUI
import SwiftUI

/// Row of the Settings window that chooses the smallest size of the files the scan finds.
struct MinimumSizePicker: View {
    let preferences: Preferences

    var body: some View {
        SettingPicker(
            LargeFilesSettings.minimumSize,
            in: preferences,
            title: Text("Minimum size of large files", bundle: .module, comment: "Setting of the large files scan: the smallest size of the files it finds. A size follows, such as “50 MB”."),
            note: Text("Takes effect the next time you scan.", bundle: .module, comment: "Note under the setting of the smallest size of the large files.")
        ) { size in
            Text(verbatim: size.formattedByteCount)
        }
    }
}
