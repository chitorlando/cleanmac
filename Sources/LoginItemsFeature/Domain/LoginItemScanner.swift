import CleanMacCore
import Foundation

/// Reads every launchd property list in a set of folders.
///
/// Only reads files: it never asks launchd anything and never loads or unloads a job.
/// Missing or unreadable folders and files that aren't valid launchd property lists are skipped.
public struct LoginItemScanner: LoginItemScanning {
    private static let plistExtension = "plist"

    private let folders: [LaunchFolder]
    private let reader: any DirectoryReading
    private let sizer: any SizeCalculating
    private let attributor: LoginItemAttributor

    public init(
        folders: [LaunchFolder],
        reader: any DirectoryReading,
        sizer: any SizeCalculating,
        attributor: LoginItemAttributor
    ) {
        self.folders = folders
        self.reader = reader
        self.sizer = sizer
        self.attributor = attributor
    }

    @concurrent
    public func scan() async -> [LoginItem] {
        folders.flatMap(items(in:))
    }

    private func items(in folder: LaunchFolder) -> [LoginItem] {
        guard reader.itemExists(at: folder.url) else { return [] }
        let plistURLs = ((try? reader.childItems(of: folder.url)) ?? []).filter(isLaunchPlist)
        return plistURLs.compactMap { item(at: $0, in: folder) }
    }

    private func isLaunchPlist(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == Self.plistExtension && !url.lastPathComponent.hasPrefix(".")
    }

    private func item(at url: URL, in folder: LaunchFolder) -> LoginItem? {
        guard
            let data = try? Data(contentsOf: url),
            let job = LaunchPlistParser.job(from: data)
        else { return nil }

        return LoginItem(
            item: CleanableItem(url: url, size: sizer.size(of: url)),
            job: job,
            scope: folder.scope,
            kind: folder.kind,
            owner: attributor.owner(of: job),
            isOrphaned: attributor.isOrphaned(job)
        )
    }
}
