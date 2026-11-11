import Testing
import UninstallerFeature

struct AppListQueryTests {
    private let apps = [
        InstalledAppFixtures.app("Zoom", bundleID: "us.zoom.xos", size: 300),
        InstalledAppFixtures.app("Café", bundleID: "com.example.coffee", size: 50),
        InstalledAppFixtures.app("App 10", size: 10, leftovers: ["app10-cache": 500]),
        InstalledAppFixtures.app("App 2", size: 200)
    ]

    private func names(_ query: AppListQuery) -> [String] {
        query.filtered(query.sorted(apps)).map(\.info.name)
    }

    @Test func sortsByNameLikeTheFinder() {
        #expect(names(AppListQuery(sortOrder: .name)) == ["App 2", "App 10", "Café", "Zoom"])
    }

    @Test func sortsByTotalSizeDescending() {
        #expect(names(AppListQuery(sortOrder: .size)) == ["App 10", "Zoom", "App 2", "Café"])
    }

    @Test func filteringKeepsTheOrderItIsGiven() {
        let matches = AppListQuery(searchText: "app").filtered(apps)

        #expect(matches.map(\.info.name) == ["App 10", "App 2"])
    }

    @Test func searchIgnoresCaseAndAccents() {
        #expect(names(AppListQuery(searchText: "CAFE")) == ["Café"])
    }

    @Test func searchMatchesTheBundleID() {
        #expect(names(AppListQuery(searchText: "zoom.XOS")) == ["Zoom"])
    }

    @Test func blankSearchShowsEveryApp() {
        #expect(names(AppListQuery(searchText: "  ")).count == apps.count)
    }

    @Test func searchWithoutMatchesShowsNothing() {
        #expect(names(AppListQuery(searchText: "photoshop")).isEmpty)
    }
}
