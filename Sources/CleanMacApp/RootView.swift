import CleanMacUI
import SwiftUI

/// Main window: sidebar with features and the selected feature on the right.
///
/// Opens on the available feature at the top of the sidebar, whatever the order
/// in which the features were registered.
struct RootView: View {
    let sections: SidebarSections

    @State private var selectedID: String?

    init(modules: [any FeatureModule], upcoming: [UpcomingFeature]) {
        let sections = SidebarSections(modules: modules, upcoming: upcoming)
        self.sections = sections
        _selectedID = State(initialValue: sections.firstModule?.id)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(sections: sections, selection: $selectedID)
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
        } detail: {
            detail
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let module = sections.modules.first(where: { $0.id == selectedID }) {
            module.makeView()
                .id(module.id)
        } else {
            FeatureBackground(theme: .neutral)
        }
    }
}
