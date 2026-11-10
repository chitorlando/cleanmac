import SwiftUI

/// Shown instead of the list when no group matches the search.
struct DuplicateGroupListEmptyView: View {
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
            return Text("No duplicates found", bundle: .module, comment: "Shown in the list when there are no groups of duplicates.")
        }
        return Text(
            "No duplicates match “\(term)”",
            bundle: .module,
            comment: "Shown when the search finds no group of duplicates. The argument is the search text."
        )
    }
}
