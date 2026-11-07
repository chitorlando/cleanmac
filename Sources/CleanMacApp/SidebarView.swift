import CleanMacUI
import SwiftUI

/// Navigation list with the features grouped by section.
///
/// Available features come first in each section, followed by the planned ones.
struct SidebarView: View {
    let modules: [any FeatureModule]
    let upcoming: [UpcomingFeature]
    @Binding var selection: String?

    var body: some View {
        List(selection: $selection) {
            ForEach(visibleSections) { section in
                Section {
                    ForEach(modules(in: section), id: \.id) { module in
                        SidebarRow(title: module.title, symbolName: module.symbolName, theme: module.theme)
                            .tag(Optional(module.id))
                    }
                    ForEach(upcoming(in: section)) { feature in
                        UpcomingSidebarRow(feature: feature)
                    }
                } header: {
                    Text(section.title)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var visibleSections: [FeatureSection] {
        FeatureSection.allCases.filter { section in
            !modules(in: section).isEmpty || !upcoming(in: section).isEmpty
        }
    }

    private func modules(in section: FeatureSection) -> [any FeatureModule] {
        modules.filter { $0.section == section }
    }

    private func upcoming(in section: FeatureSection) -> [UpcomingFeature] {
        upcoming.filter { $0.section == section }
    }
}
