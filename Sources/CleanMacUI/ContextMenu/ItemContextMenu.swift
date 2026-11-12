import SwiftUI

/// Context menu of an item row: the common actions, then the feature's own after a divider.
///
/// Use it inside `.contextMenu { }` so every row offers the same actions with the same words.
public struct ItemContextMenu<Extra: View>: View {
    private let url: URL
    private let actions: [ItemMenuAction]
    private let onToggle: () -> Void
    private let extra: Extra
    @Environment(\.fileActions) private var files

    /// - Parameters:
    ///   - actions: Usually `ItemMenuActions.standard(for:canOpen:selection:)`.
    ///   - onToggle: Called for Select and Deselect.
    ///   - extra: The feature's own actions, such as “Open in Uninstaller”.
    public init(
        url: URL,
        actions: [ItemMenuAction],
        onToggle: @escaping () -> Void = {},
        @ViewBuilder extra: () -> Extra
    ) {
        self.url = url
        self.actions = actions
        self.onToggle = onToggle
        self.extra = extra()
    }

    public var body: some View {
        ForEach(actions, id: \.self) { action in
            Button {
                action.perform(on: url, files: files, onToggle: onToggle)
            } label: {
                action.title
            }
        }
        if Extra.self != EmptyView.self {
            Divider()
            extra
        }
    }
}

public extension ItemContextMenu where Extra == EmptyView {
    init(url: URL, actions: [ItemMenuAction], onToggle: @escaping () -> Void = {}) {
        self.init(url: url, actions: actions, onToggle: onToggle) { EmptyView() }
    }
}
