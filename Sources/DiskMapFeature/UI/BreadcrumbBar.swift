import SwiftUI

/// The folders opened from the top of the map down to the focused one, each one a way back,
/// with a button to go up one level.
struct BreadcrumbBar: View {
    let breadcrumbs: [DiskNode]
    let canGoUp: Bool
    let onGoUp: () -> Void
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onGoUp) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .disabled(!canGoUp)
            .keyboardShortcut(.upArrow, modifiers: .command)
            .help(upTitle)
            .accessibilityLabel(upTitle)

            ForEach(Array(breadcrumbs.enumerated()), id: \.element.id) { index, node in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                crumb(node, at: index)
            }
        }
        .lineLimit(1)
    }

    private func crumb(_ node: DiskNode, at index: Int) -> some View {
        let isLast = index == breadcrumbs.count - 1
        return Button {
            onSelect(index)
        } label: {
            if index == 0 {
                Label(node.name, systemImage: "house.fill")
            } else {
                Text(verbatim: node.name)
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isLast ? .primary : .secondary)
        .fontWeight(isLast ? .semibold : .regular)
        .truncationMode(.middle)
        .disabled(isLast)
    }

    private var upTitle: Text {
        Text("Enclosing Folder", bundle: .module, comment: "Button that goes up one folder in the disk map.")
    }
}
