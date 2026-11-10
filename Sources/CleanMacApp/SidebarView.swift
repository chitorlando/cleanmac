import CleanMacUI
import SwiftUI

/// Navigation list with the features grouped by section.
struct SidebarView: View {
    let sections: SidebarSections
    @Binding var selection: String?

    var body: some View {
        List(selection: $selection) {
            ForEach(sections.visibleSections) { section in
                Section {
                    ForEach(sections.modules(in: section), id: \.id) { module in
                        SidebarRow(title: module.title, symbolName: module.symbolName, theme: module.theme)
                            .tag(Optional(module.id))
                    }
                    ForEach(sections.upcoming(in: section)) { feature in
                        UpcomingSidebarRow(feature: feature)
                    }
                } header: {
                    Text(section.title)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
