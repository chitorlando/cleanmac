import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

struct DirectoryJunkScannerTests {
    private let caches = URL(filePath: "/home/Library/Caches")

    private func makeScanner(
        children: [String: Int64],
        exclusions: ExclusionRules = ExclusionRules(protectedNames: [])
    ) -> DirectoryJunkScanner {
        let urls = children.keys.map { caches.appending(path: $0) }
        let sizes = Dictionary(uniqueKeysWithValues: children.map { (caches.appending(path: $0.key), $0.value) })
        return DirectoryJunkScanner(
            category: .userCaches,
            locations: [caches, URL(filePath: "/missing")],
            reader: FakeDirectoryReader(tree: [caches: urls]),
            sizer: FakeSizeCalculator(sizes: sizes),
            exclusions: exclusions
        )
    }

    @Test func returnsChildrenSortedBySizeDescending() async {
        let scanner = makeScanner(children: ["small": 10, "big": 500, "medium": 80])
        let names = await scanner.scan().map(\.name)
        #expect(names == ["big", "medium", "small"])
    }

    @Test func skipsEmptyItems() async {
        let scanner = makeScanner(children: ["empty": 0, "full": 5])
        #expect(await scanner.scan().map(\.name) == ["full"])
    }

    @Test func skipsProtectedItems() async {
        let scanner = makeScanner(
            children: ["com.apple.bird": 900, "com.example.app": 100],
            exclusions: .standard
        )
        #expect(await scanner.scan().map(\.name) == ["com.example.app"])
    }
}
