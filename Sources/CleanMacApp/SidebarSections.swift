import CleanMacUI

/// Features grouped the way the sidebar lists them.
///
/// Sections follow the order of `FeatureSection`. Within a section, available features
/// come first, in the order they were registered, followed by the planned ones.
@MainActor
struct SidebarSections {
    let modules: [any FeatureModule]
    let upcoming: [UpcomingFeature]

    /// Sections with at least one available or planned feature.
    var visibleSections: [FeatureSection] {
        FeatureSection.allCases.filter { section in
            !modules(in: section).isEmpty || !upcoming(in: section).isEmpty
        }
    }

    /// The available feature at the top of the sidebar.
    var firstModule: (any FeatureModule)? {
        FeatureSection.allCases.flatMap { modules(in: $0) }.first
    }

    func modules(in section: FeatureSection) -> [any FeatureModule] {
        modules.filter { $0.section == section }
    }

    func upcoming(in section: FeatureSection) -> [UpcomingFeature] {
        upcoming.filter { $0.section == section }
    }
}
