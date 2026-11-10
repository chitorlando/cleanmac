import CleanMacUI
import SwiftUI

/// The Finder icon of the files of a group, which all have the same contents.
struct DuplicateFileIcon: View {
    let group: DuplicateGroup
    let size: CGFloat

    var body: some View {
        if let url = group.files.first?.item.url {
            AppIconView(url: url, size: size)
        }
    }
}
