import CleanMacUI
import SwiftUI

/// Main window: sidebar with features and the selected feature on the right.
struct RootView: View {
    let modules: [any FeatureModule]
    let upcoming: [UpcomingFeature]

    @State private var selectedID: String?

    init(modules: [any FeatureModule], upcoming: [UpcomingFeature]) {
        self.modules = modules
        self.upcoming = upcoming
        _selectedID = State(initialValue: modules.first?.id)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(modules: modules, upcoming: upcoming, selection: $selectedID)
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
        } detail: {
            detail
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let module = modules.first(where: { $0.id == selectedID }) {
            module.makeView()
                .id(module.id)
        } else {
            FeatureBackground(theme: .neutral)
        }
    }
}
