import CleanMacUI
import SwiftUI

/// Large icon, name, version, bundle ID and total size of the focused app.
struct AppDetailHeader: View {
    let app: InstalledApp
    let theme: FeatureTheme

    var body: some View {
        HStack(spacing: 16) {
            AppIconView(url: app.info.url, size: 64)

            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: app.info.name)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                if let version = app.info.version {
                    Text("Version \(version)", bundle: .module, comment: "App version in the detail header, as in “Version 2.1”.")
                        .foregroundStyle(.secondary)
                }
                Text(verbatim: app.info.bundleID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.supportingText)
                    .textSelection(.enabled)
            }

            Spacer()

            Text(app.totalSize.formattedByteCount)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
        }
    }
}
