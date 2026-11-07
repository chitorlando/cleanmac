import Foundation

extension MaintenanceError {
    /// Explanation shown next to a task that did not complete.
    var explanation: String {
        switch self {
        case .authorizationCancelled:
            String(
                localized: "Not run: the administrator password wasn’t entered.",
                bundle: .module,
                comment: "Result of a maintenance task skipped because the user dismissed the password prompt."
            )
        case .cancelled:
            String(
                localized: "Not run: maintenance was cancelled.",
                bundle: .module,
                comment: "Result of a maintenance task skipped because the run was cancelled."
            )
        case .failed(let message) where message.isEmpty:
            String(
                localized: "The task failed without giving a reason.",
                bundle: .module,
                comment: "Result of a maintenance task whose tool failed without an error message."
            )
        case .failed(let message):
            String(
                localized: "Failed: \(message)",
                bundle: .module,
                comment: "Result of a failed maintenance task. The argument is the error reported by the system tool, usually in English."
            )
        case .unreadableResult:
            String(
                localized: "CleanMac couldn’t read the result of this task.",
                bundle: .module,
                comment: "Result of a maintenance task whose outcome could not be determined."
            )
        }
    }
}
