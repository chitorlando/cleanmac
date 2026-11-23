import CleanMacUI

/// Settings grouped the way the Settings window lists them.
///
/// Sections follow the order of `SettingsSection`. Within a section, settings keep the order
/// in which they were added.
struct SettingsSections {
    let items: [SettingsItem]

    /// Sections with at least one setting.
    var visibleSections: [SettingsSection] {
        SettingsSection.allCases.filter { !items(in: $0).isEmpty }
    }

    func items(in section: SettingsSection) -> [SettingsItem] {
        items.filter { $0.section == section }
    }
}
