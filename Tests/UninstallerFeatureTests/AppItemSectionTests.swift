import CleanMacCore
import Foundation
import Testing
import UninstallerFeature

struct AppItemSectionTests {
    private func leftover(_ name: String, _ kind: LeftoverKind) -> Leftover {
        Leftover(item: CleanableItem(url: URL(filePath: "/home/Library/\(name)"), size: 10), kind: kind)
    }

    @Test func startsWithTheBundleAndGroupsLeftoversByKind() {
        let info = AppBundleInfo(url: URL(filePath: "/Applications/Foo.app"), bundleID: "com.foo", name: "Foo")
        let app = InstalledApp(
            info: info,
            bundle: CleanableItem(url: info.url, size: 100),
            leftovers: [
                leftover("Logs/Foo", .logs),
                leftover("Caches/com.foo", .caches),
                leftover("Caches/Foo", .caches)
            ]
        )

        let sections = AppItemSection.sections(of: app)

        #expect(sections.map(\.category) == [.application, .leftover(.caches), .leftover(.logs)])
        #expect(sections[0].items == [app.bundle])
        #expect(sections[1].items.map(\.name) == ["com.foo", "Foo"])
        #expect(sections[1].totalSize == 20)
    }

    @Test func appsWithoutLeftoversOnlyHaveTheApplicationSection() {
        let info = AppBundleInfo(url: URL(filePath: "/Applications/Bar.app"), bundleID: "com.bar", name: "Bar")
        let app = InstalledApp(info: info, bundle: CleanableItem(url: info.url, size: 5), leftovers: [])

        #expect(AppItemSection.sections(of: app).map(\.category) == [.application])
    }
}
