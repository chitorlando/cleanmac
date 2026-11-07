import CleanMacCore
import Foundation

/// Records every command it is asked to run and fails the ones whose executable is listed.
actor SpyCommandRunner: CommandRunning {
    struct Invocation: Equatable {
        let executable: URL
        let arguments: [String]
    }

    private let failures: [URL: any Error]
    private(set) var invocations: [Invocation] = []

    init(failures: [URL: any Error] = [:]) {
        self.failures = failures
    }

    func run(_ executable: URL, arguments: [String]) async throws {
        invocations.append(Invocation(executable: executable, arguments: arguments))
        if let error = failures[executable] { throw error }
    }
}
