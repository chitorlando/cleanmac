import CleanMacCore
import Foundation
import SecurityFeature

/// Answers each tool with a configured output or failure. Other tools print nothing.
struct StubCommandRunner: CommandRunning {
    let results: [String: Result<String, CommandFailure>]

    /// - Parameter results: By the name of the executable, such as `spctl`.
    init(_ results: [String: Result<String, CommandFailure>]) {
        self.results = results
    }

    func run(_ executable: URL, arguments: [String]) async throws -> String {
        try (results[executable.lastPathComponent] ?? .success("")).get()
    }
}

/// Property lists and modification dates held in memory. It never changes once made.
struct StubProtectionFiles: ProtectionFileReading, @unchecked Sendable {
    var propertyLists: [String: [String: Any]] = [:]
    var modificationDates: [String: Date] = [:]

    func propertyList(at url: URL) -> [String: Any]? {
        propertyLists[url.path]
    }

    func modificationDate(of url: URL) -> Date? {
        modificationDates[url.path]
    }
}
