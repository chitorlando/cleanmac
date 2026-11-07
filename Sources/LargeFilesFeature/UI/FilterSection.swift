import CleanMacUI
import SwiftUI

/// A titled group of filter options, with the option that shows every file beside the title.
struct FilterSection<Content: View>: View {
    let title: Text
    /// Name of the option that clears the group, such as “All Kinds”.
    let anyTitle: Text
    let isAnySelected: Bool
    let theme: FeatureTheme
    let onSelectAny: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                title
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                AnyOptionChip(title: anyTitle, isSelected: isAnySelected, theme: theme, action: onSelectAny)
            }
            .padding(.leading, 10)
            content
        }
    }
}
