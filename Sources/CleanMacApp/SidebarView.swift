import CleanMacUI
import SwiftUI

/// Navigation list with available features and the roadmap.
struct SidebarView: View {
    let modules: [any FeatureModule]
    let upcoming: [UpcomingFeature]
    @Binding var selection: String?

    var body: some View {
        List(selection: $selection) {
            Section("Limpieza") {
                ForEach(modules, id: \.id) { module in
                    SidebarRow(title: module.title, symbolName: module.symbolName, theme: module.theme)
                        .tag(Optional(module.id))
                }
            }
            Section("Próximamente") {
                ForEach(upcoming) { feature in
                    SidebarRow(title: feature.title, symbolName: feature.symbolName, theme: .neutral)
                        .opacity(0.5)
                        .selectionDisabled()
                }
            }
        }
        .listStyle(.sidebar)
    }
}
