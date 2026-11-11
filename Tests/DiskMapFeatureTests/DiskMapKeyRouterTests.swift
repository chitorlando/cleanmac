@testable import DiskMapFeature
import Foundation
import Testing

struct DiskMapKeyRouterTests {
    private typealias Fixtures = DiskMapFixtures

    private let router = DiskMapKeyRouter(uninstallerFeatureID: "uninstaller")
    private let app = Fixtures.file("Applications/Tool.app", 120, kind: .package)
    private let movies = Fixtures.folder("Movies", [Fixtures.file("Movies/clip.mov", 100)])

    @Test func showsAHighlightedAppInTheUninstaller() {
        let route = router.route(for: .openHighlighted, highlighted: app, advice: .useUninstaller)

        #expect(route == .feature(id: "uninstaller", itemURL: app.url))
    }

    @Test func leavesAnAppToTheMapWithoutAFeatureThatUninstalls() {
        let router = DiskMapKeyRouter(uninstallerFeatureID: nil)

        #expect(router.route(for: .openHighlighted, highlighted: app, advice: .useUninstaller) == .map)
    }

    @Test func leavesEverythingButAppsToTheMap() {
        #expect(router.route(for: .openHighlighted, highlighted: movies, advice: .standardFolder) == .map)
        #expect(router.route(for: .openHighlighted, highlighted: movies, advice: .allowed) == .map)
        #expect(router.route(for: .openHighlighted, highlighted: movies, advice: .appData) == .map)
        #expect(router.route(for: .openHighlighted, highlighted: movies, advice: .protectedData) == .map)
    }

    @Test func leavesOpeningToTheMapWhileNothingIsHighlighted() {
        #expect(router.route(for: .openHighlighted, highlighted: nil, advice: nil) == .map)
    }

    @Test func leavesTheOtherKeysOnAnAppToTheMap() {
        #expect(router.route(for: .moveHighlight(by: 1), highlighted: app, advice: .useUninstaller) == .map)
        #expect(router.route(for: .moveHighlight(by: -1), highlighted: app, advice: .useUninstaller) == .map)
        #expect(router.route(for: .goUp, highlighted: app, advice: .useUninstaller) == .map)
    }
}
