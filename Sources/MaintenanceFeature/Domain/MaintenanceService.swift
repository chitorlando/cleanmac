import CleanMacCore
import Foundation

/// Runs the chosen maintenance tasks in order, continuing past individual failures.
/// Administrator tasks share one password prompt: they run together as a single batch
/// when the first of them comes up.
public struct MaintenanceService: Sendable {
    private let runner: any CommandRunning
    private let privilegedRunner: any PrivilegedCommandRunning

    public init(
        runner: any CommandRunning = CommandRunner(),
        privilegedRunner: any PrivilegedCommandRunning = PrivilegedCommandRunner()
    ) {
        self.runner = runner
        self.privilegedRunner = privilegedRunner
    }

    @concurrent
    public func run(_ tasks: [MaintenanceTaskKind]) async -> MaintenanceReport {
        let tasks = tasks.uniquedByID()
        let administratorTasks = tasks.filter { $0.privilege == .administrator }
        var batchOutcome: MaintenanceOutcome?
        var results: [MaintenanceTaskResult] = []

        for task in tasks {
            let outcome: MaintenanceOutcome
            switch task.privilege {
            case .user:
                outcome = await runAsUser(task)
            case .administrator:
                if let batchOutcome {
                    outcome = batchOutcome
                } else {
                    outcome = await runAsAdministrator(administratorTasks)
                    batchOutcome = outcome
                }
            }
            results.append(MaintenanceTaskResult(task: task, outcome: outcome))
        }
        return MaintenanceReport(results: results)
    }

    private func runAsUser(_ task: MaintenanceTaskKind) async -> MaintenanceOutcome {
        await outcome {
            for command in task.commands {
                try await runner.run(command.executable, arguments: command.arguments)
            }
        }
    }

    private func runAsAdministrator(_ tasks: [MaintenanceTaskKind]) async -> MaintenanceOutcome {
        await outcome {
            try await privilegedRunner.run(tasks.flatMap(\.commands))
        }
    }

    private func outcome(of work: () async throws -> Void) async -> MaintenanceOutcome {
        guard !Task.isCancelled else { return .failed(.cancelled) }
        do {
            try await work()
            return .succeeded
        } catch {
            return .failed(MaintenanceError(error))
        }
    }
}
