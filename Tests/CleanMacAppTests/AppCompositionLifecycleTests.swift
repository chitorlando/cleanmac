@testable import CleanMacApp
import CleanMacCore
import Testing

@MainActor
struct AppCompositionLifecycleTests {
    /// The menu of the monitor in the menu bar brings a window back, so the app stays for it.
    @Test func keepsRunningWithoutWindowsWhileTheMonitorIsInTheMenuBar() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage())

        #expect(AppComposition.keepsRunningWithoutWindows(preferences: preferences))
    }

    @Test func quitsWithItsLastWindowWhenTheMonitorIsNotInTheMenuBar() {
        let preferences = Preferences(storage: InMemoryPreferenceStorage(["monitor.showsMenuBarExtra": false]))

        #expect(!AppComposition.keepsRunningWithoutWindows(preferences: preferences))
    }
}
