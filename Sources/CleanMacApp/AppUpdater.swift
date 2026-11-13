import Combine
import Foundation
import Sparkle

/// Keeps Sparkle alive for the app's lifetime and mirrors its menu availability.
@MainActor
final class AppUpdater: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    private let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: &$canCheckForUpdates)

        // A package executable launched by swift run (or a test host) cannot
        // replace itself as an installed app. Use make run to test updates.
        if Bundle.main.bundleURL.pathExtension == "app" {
            controller.startUpdater()
        }
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
