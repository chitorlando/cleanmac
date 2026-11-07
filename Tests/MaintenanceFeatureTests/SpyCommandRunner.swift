import CleanMacCore
import Foundation

/// Records every command it is asked to run, fails the ones whose executable is listed
/// and answers the rest with their configured output.
actor SpyCommandRunner: CommandRunning {
    struct Invocation: Equatable {
        let executable: URL
        let arguments: [String]
    }

    private let failures: [URL: any Error]
    private let outputs: [URL: String]
    private(set) var invocations: [Invocation] = []

    init(failures: [URL: any Error] = [:], outputs: [URL: String] = [:]) {
        self.failures = failures
        self.outputs = outputs
    }

    func run(_ executable: URL, arguments: [String]) async throws -> String {
        invocations.append(Invocation(executable: executable, arguments: arguments))
        if let error = failures[executable] { throw error }
        return outputs[executable] ?? ""
    }
}
