import CleanMacUI
import SwiftUI

/// One installed app in the list. Clicking it shows its details; the checkbox selects it.
/// Its context menu has the common item actions and, while the app is open, Quit App.
struct AppListRow: View {
    let app: InstalledApp
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    private var isFocused: Bool { viewModel.focusedAppID == app.id }
    private var isRunning: Bool { viewModel.isRunning(app) }

    var body: some View {
        HStack(spacing: 10) {
            TriStateCheckbox(
                state: CheckState(viewModel.selectionState(of: app)),
                tint: theme.primary,
                label: Text(verbatim: app.info.name)
            ) {
                viewModel.toggle(app)
            }
            .disabled(isRunning)

            AppIconView(url: app.info.url, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: app.info.name)
                    .lineLimit(1)
                if let version = app.info.version {
                    Text(verbatim: version)
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if isRunning {
                RunningAppBadge()
            }

            Text(app.totalSize.formattedByteCount)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SelectionHighlight(isSelected: isFocused, theme: theme))
        .contentShape(.rect(cornerRadius: 10))
        .onTapGesture { viewModel.focusedAppID = app.id }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isFocused ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction { viewModel.focusedAppID = app.id }
        .contextMenu { contextMenu }
    }

    /// A running app can't be selected, so the menu offers to quit it instead.
    private var contextMenu: some View {
        ItemContextMenu(
            url: app.info.url,
            selection: ItemMenuSelection(isSelected: viewModel.selectionState(of: app) == .all, canChange: !isRunning),
            onToggle: { viewModel.toggle(app) }
        ) {
            if isRunning {
                Divider()
                Button {
                    Task { await viewModel.quit(app) }
                } label: {
                    Text("Quit App", bundle: .module, comment: "Button that asks a running app to quit.")
                }
                .disabled(viewModel.isQuitting(app))
            }
        }
    }
}
