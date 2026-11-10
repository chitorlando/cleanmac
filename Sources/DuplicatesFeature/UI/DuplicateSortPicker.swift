import SwiftUI

/// Menu to choose how the groups of duplicates are ordered.
struct DuplicateSortPicker: View {
    @Binding var sortOrder: DuplicateSortOrder

    var body: some View {
        Picker(selection: $sortOrder) {
            ForEach(DuplicateSortOrder.allCases, id: \.self) { order in
                Text(verbatim: order.title).tag(order)
            }
        } label: {
            label
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .help(label)
        .fixedSize()
    }

    private var label: Text {
        Text("Sort by", bundle: .module, comment: "Label of the menu that orders the groups of duplicates.")
    }
}
