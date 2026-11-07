import CleanMacCore
import Foundation

/// Runs the chosen maintenance tasks in order, continuing past individual failures.
/// Administrator tasks share one password prompt: they run together as a single batch
/// when the first of them comes up, and each one still gets its own outcome.
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
        var administratorOutcomes: [MaintenanceTaskKind: MaintenanceOutcome]?
        var results: [MaintenanceTaskResult] = []

        for task in tasks {
            let outcome: MaintenanceOutcome
            switch task.privilege {
            case .user:
                outcome = await runAsUser(task)
            case .administrator:
                let outcomes: [MaintenanceTaskKind: MaintenanceOutcome]
                if let administratorOutcomes {
                    outcomes = administratorOutcomes
                } else {
                    outcomes = await runAsAdministrator(administratorTasks)
                    administratorOutcomes = outcomes
                }
                outcome = outcomes[task] ?? .failed(.unreadableResult)
            }
            results.append(MaintenanceTaskResult(task: task, outcome: outcome))
        }
        return MaintenanceReport(results: results)
    }

    private func runAsUser(_ task: MaintenanceTaskKind) async -> MaintenanceOutcome {
        guard !Task.isCancelled else { return .failed(.cancelled) }
        do {
            for command in task.commands {
                try await runner.run(command.executable, arguments: command.arguments)
            }
            return .succeeded
        } catch {
            return .failed(MaintenanceError(error))
        }
    }

    /// Runs every administrator task in one batch. If the batch cannot run at all,
    /// every task shares that error.
    private func runAsAdministrator(
        _ tasks: [MaintenanceTaskKind]
    ) async -> [MaintenanceTaskKind: MaintenanceOutcome] {
        let outcomes: [MaintenanceOutcome]
        if Task.isCancelled {
            outcomes = Array(repeating: .failed(.cancelled), count: tasks.count)
        } else {
            do {
                outcomes = try await privilegedRunner.run(tasks.map(\.commands))
            } catch {
                outcomes = Array(repeating: .failed(MaintenanceError(error)), count: tasks.count)
            }
        }
        return Dictionary(uniqueKeysWithValues: zip(tasks, outcomes))
    }
}
