import CleanMacUI
import SwiftUI

/// Shown in the list when the filters leave no file.
struct NoMatchingFilesView: View {
    let theme: FeatureTheme
    let onClearFilters: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 40))
                .foregroundStyle(theme.gradient)
            Text("No Files Match the Filters", bundle: .module, comment: "Title shown when the filters leave the list of large files empty.")
                .font(.headline)
            Button(action: onClearFilters) {
                Text("Clear Filters", bundle: .module, comment: "Button that removes every filter and search of the large files list.")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(theme.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
