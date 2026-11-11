import AppKit
import CleanMacUI
import SwiftUI

/// One login item: a checkbox for the user's agents or a lock for shared items, with
/// its app, when it runs and a button that reveals its property list in Finder.
struct LoginItemRow: View {
    let item: LoginItem
    let isSelected: Bool
    let theme: FeatureTheme
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            selectionControl
                .frame(width: 22)
            LoginItemIcon(item: item)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(verbatim: item.displayName).lineLimit(1)
                    LoginItemBadges(item: item)
                }
                Text(verbatim: details)
                    .font(.caption)
                    .foregroundStyle(.supportingText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            Button(action: revealInFinder) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help(revealLabel)
            .accessibilityLabel(revealLabel)
        }
        .padding(.leading, 4)
    }

    @ViewBuilder
    private var selectionControl: some View {
        if item.isRemovable {
            TriStateCheckbox(
                state: isSelected ? .checked : .unchecked,
                tint: theme.primary,
                label: Text(verbatim: item.displayName),
                action: onToggle
            )
        } else {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
                .help(Text("Removing it needs an administrator.", bundle: .module, comment: "Tooltip of the lock on a shared login item."))
        }
    }

    /// The label when the app's name is shown instead, and when it runs.
    private var details: String {
        item.owner == nil ? item.job.behavior : "\(item.job.label) · \(item.job.behavior)"
    }

    private var revealLabel: Text {
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals a login item’s property list in Finder.")
    }

    private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([item.plistURL])
    }
}
