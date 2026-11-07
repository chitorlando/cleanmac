import SwiftUI

/// Shown instead of the list when no app matches the search, or no app was found.
struct AppListEmptyView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            message
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var message: Text {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return Text("No apps found", bundle: .module, comment: "Shown when the scan finds no installed apps.")
        }
        return Text(
            "No apps match “\(term)”",
            bundle: .module,
            comment: "Shown when the search finds no app. The argument is the search text."
        )
    }
}
