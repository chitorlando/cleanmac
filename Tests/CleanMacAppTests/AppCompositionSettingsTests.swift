@testable import CleanMacApp
import CleanMacCore
import CleanMacUI
import SwiftUI
import Testing

@MainActor
struct AppCompositionSettingsTests {
    private func settings(of modules: [any FeatureModule]) -> SettingsSections {
        AppComposition.makeSettings(modules: modules, preferences: Preferences(storage: InMemoryPreferenceStorage()))
    }

    @Test func listsTheLanguageAndTheSoundEffectsInTheGeneralSection() {
        let general = settings(of: []).items(in: .general).map { $0.id }

        #expect(general == ["AppleLanguages", "soundEffects.isEnabled"])
    }

    /// The folders left out are shared by the large files and the duplicates features, so the
    /// window shows them once, after the analysis settings of every feature.
    @Test func listsTheExcludedFoldersOnceAfterTheAnalysisSettingsOfTheFeatures() {
        let feature = FeatureWithSetting("large-files.minimumSize", in: .analysis)

        let analysis = settings(of: [feature]).items(in: .analysis).map(\.id)

        #expect(analysis == ["large-files.minimumSize", "scans.excludedFolders"])
    }
}

/// Feature module that only adds one setting to the Settings window.
@MainActor
private final class FeatureWithSetting: FeatureModule {
    let id = "feature"
    let title = "Feature"
    let symbolName = "circle"
    let theme = FeatureTheme.neutral
    let section = FeatureSection.files
    let settings: [SettingsItem]

    init(_ settingID: String, in section: SettingsSection) {
        settings = [SettingsItem(id: settingID, section: section) { EmptyView() }]
    }

    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
