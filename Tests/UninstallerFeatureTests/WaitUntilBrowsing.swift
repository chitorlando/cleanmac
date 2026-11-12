import Foundation
import Testing
import UninstallerFeature

/// Waits until the loading started by `focusApp(at:)` ends.
///
/// It gives up after a few seconds and records an issue, so that a load that never ends,
/// such as one that keeps starting again, fails the test instead of hanging the whole run.
@MainActor
func waitUntilBrowsing(_ viewModel: UninstallerViewModel, timeout: Duration = .seconds(5)) async {
    let deadline = ContinuousClock.now + timeout
    while viewModel.phase != .browsing {
        guard ContinuousClock.now < deadline else {
            Issue.record("The list was still loading after \(timeout).")
            return
        }
        await Task.yield()
    }
}
