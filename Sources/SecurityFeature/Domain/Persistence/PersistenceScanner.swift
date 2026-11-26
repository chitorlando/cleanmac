import CleanMacCore
import Foundation

/// Finds the login and background items that deserve a look.
public protocol PersistenceScanning: Sendable {
    /// Only the items with a concern, in the order of their folders.
    func findings() -> [PersistenceFinding]
}

/// Reads the launchd property lists of a set of folders, as the login items feature does, and
/// checks where each job's program is and how it's signed.
///
/// Only reads files: it never asks launchd anything. Folders and files that can't be read, and
/// files that aren't launchd property lists, are skipped.
public struct PersistenceScanner: PersistenceScanning {
    private static let plistExtension = "plist"

    private let folders: [LaunchFolder]
    private let reader: any DirectoryReading
    private let attributor: LoginItemAttributor
    private let inspector: any CodeSignatureInspecting

    public init(
        folders: [LaunchFolder],
        reader: any DirectoryReading,
        attributor: LoginItemAttributor,
        inspector: any CodeSignatureInspecting
    ) {
        self.folders = folders
        self.reader = reader
        self.attributor = attributor
        self.inspector = inspector
    }

    public func findings() -> [PersistenceFinding] {
        folders.flatMap { folder in
            plists(in: folder).compactMap { finding(at: $0, in: folder) }
        }
    }

    private func plists(in folder: LaunchFolder) -> [URL] {
        ((try? reader.childItems(of: folder.url)) ?? [])
            .filter { $0.pathExtension.lowercased() == Self.plistExtension && !$0.lastPathComponent.hasPrefix(".") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func finding(at url: URL, in folder: LaunchFolder) -> PersistenceFinding? {
        guard
            let data = try? Data(contentsOf: url),
            let job = LaunchPlistParser.job(from: data)
        else { return nil }

        let signatureConcern = job.programURL.flatMap { program in
            PersistenceRules.signatureConcern(
                of: SignatureClassifier.classify(inspector.facts(forCodeAt: program), gatekeeper: nil)
            )
        }
        let concerns = [signatureConcern].compactMap { $0 } + PersistenceRules.locationConcerns(of: job)
        guard !concerns.isEmpty else { return nil }

        return PersistenceFinding(
            plistURL: url,
            job: job,
            kind: folder.kind,
            scope: folder.scope,
            owner: attributor.owner(of: job),
            concerns: concerns
        )
    }
}
