import AppKit
import CleanMacCore
import SwiftUI

/// Row of the Settings window with a list of folders, which the user adds with the folder
/// chooser and removes one by one.
///
/// Shows each folder with its icon, its name and its path, and keeps every change in the
/// preferences as soon as it's made. A folder chosen twice is listed once.
@MainActor
public struct SettingFolderList: View {
    private let setting: Setting<[String]>
    private let preferences: Preferences
    private let title: Text
    private let note: Text?
    private let emptyNote: Text
    private let refusalNote: Text
    private let startingFolder: URL?
    private let folderToAdd: (URL) -> URL?

    @State private var list: FolderPathList
    @State private var refusedSome = false

    /// - Parameters:
    ///   - title: Name of the setting.
    ///   - note: What the user has to know about the setting, shown under its name.
    ///   - emptyNote: Shown in place of the folders while there are none.
    ///   - refusalNote: Shown under the folders when the list didn't take some of the last
    ///     ones chosen. It says which folders it takes.
    ///   - startingFolder: Where the folder chooser opens.
    ///   - folderToAdd: The folder to add for one the user chose, which may spell it another
    ///     way, or `nil` when the list doesn't take it.
    public init(
        _ setting: Setting<[String]>,
        in preferences: Preferences,
        title: Text,
        note: Text? = nil,
        emptyNote: Text,
        refusalNote: Text,
        startingFolder: URL? = nil,
        folderToAdd: @escaping (URL) -> URL? = { $0 }
    ) {
        self.setting = setting
        self.preferences = preferences
        self.title = title
        self.note = note
        self.emptyNote = emptyNote
        self.refusalNote = refusalNote
        self.startingFolder = startingFolder
        self.folderToAdd = folderToAdd
        _list = State(initialValue: FolderPathList(preferences.value(of: setting)))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    title
                    if let note {
                        secondary(note)
                    }
                }
                Spacer(minLength: 0)
                Button {
                    chooseFolders()
                } label: {
                    Text("Add Folder…", bundle: .module, comment: "Button of a setting with a list of folders. It opens the folder chooser to add more.")
                }
            }
            if list.paths.isEmpty {
                secondary(emptyNote)
            } else {
                ForEach(list.paths, id: \.self) { path in
                    SettingFolderRow(folder: URL(filePath: path, directoryHint: .isDirectory)) {
                        remove(path)
                    }
                }
            }
            if refusedSome {
                secondary(refusalNote)
            }
        }
    }

    private func secondary(_ text: Text) -> some View {
        text
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Opens the folder chooser and adds the folders the user chooses, if the list takes them.
    private func chooseFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.directoryURL = startingFolder
        panel.prompt = String(localized: "Add", bundle: .module, comment: "Button of the folder chooser opened from a setting with a list of folders. It adds the chosen folders to the list.")
        guard panel.runModal() == .OK else { return }
        refusedSome = !list.add(panel.urls, as: folderToAdd).isEmpty
        save()
    }

    private func remove(_ path: String) {
        list.remove(path)
        refusedSome = false
        save()
    }

    private func save() {
        preferences.set(list.paths, for: setting)
    }
}

/// A folder of a `SettingFolderList`, with the button that takes it out of the list.
private struct SettingFolderRow: View {
    let folder: URL
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            AppIconView(url: folder, size: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: folder.folderDisplayName)
                    .lineLimit(1)
                Text(verbatim: folder.tildeAbbreviatedPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            Button(action: remove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help(removeLabel)
            .accessibilityLabel(removeLabel)
        }
    }

    private var removeLabel: Text {
        Text("Remove from the List", bundle: .module, comment: "Tooltip and accessibility label of the button that takes a folder out of a list of folders in the Settings window.")
    }
}
