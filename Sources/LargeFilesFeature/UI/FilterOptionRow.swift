import CleanMacUI
import SwiftUI

/// One choosable filter option with the number of files it would show.
struct FilterOptionRow: View {
    let title: String
    var symbolName: String?
    let count: Int
    let isSelected: Bool
    let theme: FeatureTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(theme.gradient))
                        .frame(width: 18)
                }
                Text(verbatim: title)
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: 4)
                Text(count, format: .number)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .opacity(count == 0 && !isSelected ? 0.45 : 1)
        }
        .buttonStyle(FilterOptionStyle(isSelected: isSelected, theme: theme))
    }
}
