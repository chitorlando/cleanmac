import CleanMacCore
import Foundation
import SystemJunkFeature
import Testing

struct JunkScanServiceTests {
    private struct StubScanner: JunkScanner {
        let category: JunkCategory
        let items: [CleanableItem]

        func scan() async -> [CleanableItem] { items }
    }

    @Test func emitsOneResultPerScanner() async {
        let item = CleanableItem(url: URL(filePath: "/tmp/log"), size: 42)
        let service = JunkScanService(scanners: [
            StubScanner(category: .userCaches, items: []),
            StubScanner(category: .userLogs, items: [item])
        ])

        var results: [CategoryScanResult] = []
        for await result in service.scan() {
            results.append(result)
        }

        #expect(results.count == 2)
        #expect(results.first { $0.category == .userLogs }?.totalSize == 42)
    }
}
