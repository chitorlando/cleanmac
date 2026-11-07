import CleanMacUI
import SwiftUI

/// Navigation list with available features and the roadmap.
struct SidebarView: View {
    let modules: [any FeatureModule]
    let upcoming: [UpcomingFeature]
    @Binding var selection: String?

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(modules, id: \.id) { module in
                    SidebarRow(title: module.title, symbolName: module.symbolName, theme: module.theme)
                        .tag(Optional(module.id))
                }
            } header: {
                Text("Cleanup", bundle: .module, comment: "Sidebar section with the available features.")
            }
            Section {
                ForEach(upcoming) { feature in
                    SidebarRow(title: feature.title, symbolName: feature.symbolName, theme: .neutral)
                        .opacity(0.5)
                        .selectionDisabled()
                }
            } header: {
                Text("Coming Soon", bundle: .module, comment: "Sidebar section with features not implemented yet.")
            }
        }
        .listStyle(.sidebar)
    }
}
