import CleanMacCore
import Foundation
import Observation

/// Coordinates choosing and running maintenance tasks.
///
/// Nothing is chosen at first: each task changes the system, so the user picks
/// them by hand. Chosen tasks always run in the order of `MaintenanceTaskKind.allCases`.
@MainActor
@Observable
public final class MaintenanceViewModel {
    public private(set) var phase = MaintenancePhase.choosing
    public private(set) var selection: Set<MaintenanceTaskKind> = []

    /// Every task the user can choose, in the order they run.
    public let tasks = MaintenanceTaskKind.allCases

    private let runner: any MaintenanceRunning
    @ObservationIgnored private var activeTask: Task<Void, Never>?

    public init(runner: any MaintenanceRunning) {
        self.runner = runner
    }

    // MARK: Derived state

    /// Chosen tasks in the order they run.
    public var selectedTasks: [MaintenanceTaskKind] { tasks.filter(selection.contains) }
    public var selectedCount: Int { selection.count }
    public var hasSelection: Bool { !selection.isEmpty }

    /// Whether running the chosen tasks will ask for the administrator password, once.
    public var requiresAdministrator: Bool {
        selection.contains { $0.privilege == .administrator }
    }

    /// State of the "select all" checkbox.
    public var allSelectionState: ItemSelection.State {
        switch selection.count {
        case 0: .none
        case tasks.count: .all
        default: .some
        }
    }

    // MARK: Selection

    public func isSelected(_ task: MaintenanceTaskKind) -> Bool {
        selection.contains(task)
    }

    public func toggle(_ task: MaintenanceTaskKind) {
        guard phase == .choosing else { return }
        if selection.remove(task) == nil {
            selection.insert(task)
        }
    }

    /// Chooses every task, or clears the choice when all are already chosen.
    public func toggleAll() {
        guard phase == .choosing else { return }
        selection = allSelectionState == .all ? [] : Set(tasks)
    }

    // MARK: Actions

    @discardableResult
    public func run() -> Task<Void, Never>? {
        guard phase == .choosing, hasSelection else { return nil }
        let chosen = selectedTasks
        phase = .running
        let task = Task {
            let report = await runner.run(chosen)
            guard !Task.isCancelled else { return }
            phase = .finished(report)
        }
        activeTask = task
        return task
    }

    /// Leaves the results and starts over with nothing chosen.
    public func done() {
        guard case .finished = phase else { return }
        selection = []
        phase = .choosing
    }
}
