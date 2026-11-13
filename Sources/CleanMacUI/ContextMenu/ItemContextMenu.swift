import SwiftUI

/// Context menu of an item row: the entries of an `ItemMenu`, then the feature's own.
///
/// Use it inside `.contextMenu { }` so every row offers the same entries with the same words.
/// The actions other features offer come from the `featureItemActions` environment value.
public struct ItemContextMenu<Extra: View>: View {
    private let url: URL
    private let isFolder: Bool
    private let canOpen: Bool
    private let selection: ItemMenuSelection
    private let onToggle: () -> Void
    private let extra: Extra
    @Environment(\.fileActions) private var files
    @Environment(\.openFeature) private var openFeature
    @Environment(\.featureItemActions) private var featureActions

    /// - Parameters:
    ///   - isFolder, canOpen, selection: See `ItemMenu`.
    ///   - onToggle: Called for Select and Deselect.
    ///   - extra: The feature's own entries, such as “Quit App”, after a `Divider()`
    ///     that the feature adds only when it shows any of them.
    public init(
        url: URL,
        isFolder: Bool = false,
        canOpen: Bool = true,
        selection: ItemMenuSelection,
        onToggle: @escaping () -> Void = {},
        @ViewBuilder extra: () -> Extra
    ) {
        self.url = url
        self.isFolder = isFolder
        self.canOpen = canOpen
        self.selection = selection
        self.onToggle = onToggle
        self.extra = extra()
    }

    public var body: some View {
        let menu = ItemMenu(url: url, isFolder: isFolder, canOpen: canOpen, selection: selection, featureActions: featureActions)
        ForEach(Array(menu.sections.enumerated()), id: \.offset) { index, actions in
            if index > 0 {
                Divider()
            }
            ForEach(actions) { action in
                Button {
                    action.perform(on: url, files: files, openFeature: openFeature, onToggle: onToggle)
                } label: {
                    Label {
                        action.title
                    } icon: {
                        Image(systemName: action.symbolName)
                    }
                }
            }
        }
        extra
    }
}

public extension ItemContextMenu where Extra == EmptyView {
    init(
        url: URL,
        isFolder: Bool = false,
        canOpen: Bool = true,
        selection: ItemMenuSelection,
        onToggle: @escaping () -> Void = {}
    ) {
        self.init(url: url, isFolder: isFolder, canOpen: canOpen, selection: selection, onToggle: onToggle) { EmptyView() }
    }
}
