import CleanMacUI
import SwiftUI

/// Content of the Settings window: a form with the settings of the app and of its features,
/// grouped by section, on the canvas of the app. The window is as tall as its settings.
struct SettingsView: View {
    private static let width: CGFloat = 460

    let sections: SettingsSections

    var body: some View {
        FeatureScreen(theme: .neutral) {
            Form {
                ForEach(sections.visibleSections) { section in
                    Section {
                        ForEach(sections.items(in: section)) { item in
                            item.makeView()
                        }
                    } header: {
                        Text(section.title)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .scrollBouncesOnlyWhenContentOverflows()
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: Self.width)
    }
}
