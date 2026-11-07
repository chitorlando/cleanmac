import SwiftUI

/// Menu to choose how the files are ordered.
struct LargeFileSortPicker: View {
    @Binding var sortOrder: LargeFileSortOrder

    var body: some View {
        Picker(selection: $sortOrder) {
            ForEach(LargeFileSortOrder.allCases, id: \.self) { order in
                Text(verbatim: order.title).tag(order)
            }
        } label: {
            Text("Sort by", bundle: .module, comment: "Label of the menu that orders the list of large files.")
        }
        .pickerStyle(.menu)
        .fixedSize()
    }
}
