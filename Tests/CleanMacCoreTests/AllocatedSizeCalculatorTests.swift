import CleanMacCore
import Foundation
import Testing

struct AllocatedSizeCalculatorTests {
    @Test func measuresFilesInsideNestedFolders() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let nested = root.appending(path: "nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try Data(count: 10_000).write(to: nested.appending(path: "file.bin"))

        #expect(AllocatedSizeCalculator().size(of: root) >= 10_000)
    }

    @Test func returnsZeroForMissingItems() {
        let missing = URL(filePath: "/nonexistent/\(UUID().uuidString)")
        #expect(AllocatedSizeCalculator().size(of: missing) == 0)
    }
}
