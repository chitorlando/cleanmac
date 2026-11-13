import CleanMacCore
import SwiftUI

/// One item that couldn't be moved: its name, what happened in plain words and a button that
/// shows it in Finder, where it can be moved by hand. The system's own text is the tooltip.
struct CleanupFailureRow: View {
    let failure: CleanupFailure
    @Environment(\.fileActions) private var files

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: failure.item.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                failure.kind.message
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .help(Text(verbatim: failure.reason))
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text(verbatim: failure.reason))

            if failure.kind != .missing {
                Button {
                    files.showInFinder(failure.item.url)
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(.borderless)
                .help(revealLabel)
                .accessibilityLabel(revealLabel)
                .accessibilityValue(Text(verbatim: failure.item.name))
            }
        }
    }

    private var revealLabel: Text {
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals an item in Finder.")
    }
}
