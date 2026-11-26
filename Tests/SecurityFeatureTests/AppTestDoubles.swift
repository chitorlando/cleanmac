import CleanMacCore
import Foundation
import os
import SecurityFeature

/// A folder tree in memory: each folder's path with the names of its items.
struct StubDirectoryReader: DirectoryReading {
    let tree: [String: [String]]

    func itemExists(at url: URL) -> Bool {
        tree[url.path] != nil || tree[url.deletingLastPathComponent().path]?.contains(url.lastPathComponent) == true
    }

    func childItems(of directory: URL) throws -> [URL] {
        guard let names = tree[directory.path] else { throw CocoaError(.fileReadNoSuchFile) }
        return names.map { directory.appending(path: $0) }
    }
}

/// Signature facts by path, valid and from a notarized developer unless told otherwise.
/// Records how many inspections run at once.
final class StubSignatureInspector: CodeSignatureInspecting, Sendable {
    private struct State {
        var running = 0
        var mostRunning = 0
    }

    private let factsByPath: [String: SignatureFacts]
    private let state = OSAllocatedUnfairLock(initialState: State())

    init(_ factsByPath: [String: SignatureFacts] = [:]) {
        self.factsByPath = factsByPath
    }

    var mostRunningAtOnce: Int { state.withLock { $0.mostRunning } }

    func facts(forCodeAt url: URL) -> SignatureFacts {
        state.withLock { state in
            state.running += 1
            state.mostRunning = max(state.mostRunning, state.running)
        }
        Thread.sleep(forTimeInterval: 0.005)
        state.withLock { $0.running -= 1 }
        return factsByPath[url.path] ?? Self.notarized
    }

    static var notarized: SignatureFacts {
        var facts = SignatureFacts(validity: .valid)
        facts.isIssuedByApple = true
        facts.isDeveloperID = true
        facts.isNotarized = true
        facts.certificateSubject = "Developer ID Application: Example Ltd (ABCDE12345)"
        return facts
    }

    static var developerID: SignatureFacts {
        var facts = notarized
        facts.isNotarized = false
        return facts
    }

    static var adHoc: SignatureFacts {
        var facts = SignatureFacts(validity: .valid)
        facts.isAdHoc = true
        return facts
    }
}

/// Gives the same verdict about every app and counts how often it was asked.
final class SpyGatekeeper: GatekeeperAssessing, Sendable {
    private let answer: GatekeeperVerdict
    private let askedPaths = OSAllocatedUnfairLock(initialState: [String]())

    init(_ answer: GatekeeperVerdict = .accepted) {
        self.answer = answer
    }

    var asked: [String] { askedPaths.withLock { $0 } }

    func verdict(forAppAt url: URL) -> GatekeeperVerdict {
        askedPaths.withLock { $0.append(url.path) }
        return answer
    }
}

/// Finds a fixed list of apps.
struct StubAppFinder: AppFinding {
    let urls: [URL]

    func apps() -> [URL] { urls }
}

/// Reports fixed protections.
struct StubProtectionReader: ProtectionReading {
    var checks: [ProtectionCheck] = []

    func protections() async -> [ProtectionCheck] { checks }
}
