import SwiftUI

/// Name of a setting in the Settings window, with what the user has to know about it under it.
struct SettingLabel: View {
    let title: Text
    let note: Text?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            title
            if let note {
                note
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
