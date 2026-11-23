@testable import CleanMacApp
import CleanMacUI
import SwiftUI
import Testing

@MainActor
struct SettingsSectionsTests {
    private func item(_ id: String, in section: SettingsSection) -> SettingsItem {
        SettingsItem(id: id, section: section) { EmptyView() }
    }

    @Test func sectionsFollowTheirOwnOrderRatherThanTheOrderOfTheSettings() {
        let sections = SettingsSections(items: [item("interval", in: .monitor), item("language", in: .general)])

        #expect(sections.visibleSections == [.general, .monitor])
    }

    @Test func sectionsWithoutSettingsAreHidden() {
        let sections = SettingsSections(items: [item("interval", in: .monitor)])

        #expect(sections.visibleSections == [.monitor])
        #expect(sections.items(in: .analysis).isEmpty)
    }

    @Test func settingsKeepTheOrderTheyWereAddedInWithinASection() {
        let sections = SettingsSections(items: [
            item("large-files", in: .analysis),
            item("interval", in: .monitor),
            item("duplicates", in: .analysis)
        ])

        #expect(sections.items(in: .analysis).map(\.id) == ["large-files", "duplicates"])
    }

    @Test func noSettingsMeanNoSections() {
        #expect(SettingsSections(items: []).visibleSections.isEmpty)
    }
}
