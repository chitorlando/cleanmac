import CleanMacCore
import CleanMacUI
import SwiftUI

/// Row of the Settings window that chooses the smallest size of the files the scan compares.
struct MinimumSizePicker: View {
    let preferences: Preferences

    var body: some View {
        SettingPicker(
            DuplicatesSettings.minimumSize,
            in: preferences,
            title: Text("Minimum size of duplicates", bundle: .module, comment: "Setting of the duplicates scan: the smallest size of the files it compares. A size follows, such as “1 MB”."),
            note: Text("Takes effect the next time you scan.", bundle: .module, comment: "Note under the setting of the smallest size of the duplicates.")
        ) { size in
            Text(verbatim: size.formattedByteCount)
        }
    }
}
