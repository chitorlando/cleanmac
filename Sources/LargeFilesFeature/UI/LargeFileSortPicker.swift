import SwiftUI

/// Menu to choose how the files are ordered.
///
/// Its label is just an icon, which leaves the search box room for its placeholder
/// at the smallest window size. The name stays for VoiceOver and the tooltip.
struct LargeFileSortPicker: View {
    @Binding var sortOrder: LargeFileSortOrder

    var body: some View {
        Picker(selection: $sortOrder) {
            ForEach(LargeFileSortOrder.allCases, id: \.self) { order in
                Text(verbatim: order.title).tag(order)
            }
        } label: {
            Label {
                title
            } icon: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .labelStyle(.iconOnly)
        }
        .pickerStyle(.menu)
        .fixedSize()
        .help(title)
    }

    private var title: Text {
        Text("Sort by", bundle: .module, comment: "Label of the menu that orders the list of large files.")
    }
}
