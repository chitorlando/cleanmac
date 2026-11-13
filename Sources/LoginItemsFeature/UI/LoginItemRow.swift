import CleanMacUI
import SwiftUI

/// One login item: a checkbox for the user's agents or a lock for shared items, with
/// its app, when it runs and a button that reveals its property list in Finder.
///
/// Its context menu acts on the property list, offers what other features do with the app it
/// belongs to, such as showing it in the Uninstaller, and shows its program in Finder.
struct LoginItemRow: View {
    let item: LoginItem
    let isSelected: Bool
    let theme: FeatureTheme
    let onToggle: () -> Void
    @Environment(\.fileActions) private var files

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
        .contextMenu { contextMenu }
    }

    /// Shared items need an administrator, so they're never offered Select.
    private var contextMenu: some View {
        ItemContextMenu(
            url: item.plistURL,
            featureTarget: item.owner.map { FeatureItemTarget(itemAt: $0.appURL, isFolder: false) },
            selection: ItemMenuSelection(isSelected: isSelected, canChange: item.isRemovable),
            onToggle: onToggle
        ) {
            if let programURL {
                Divider()
                Button {
                    files.showInFinder(programURL)
                } label: {
                    Text("Show Program in Finder", bundle: .module, comment: "Context menu item that reveals the program a login item starts.")
                }
            }
        }
    }

    /// The program the item starts, when it's still on disk.
    private var programURL: URL? {
        item.isOrphaned ? nil : item.job.programURL
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
        files.showInFinder(item.plistURL)
    }
}
