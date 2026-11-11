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

    @Test func sumsEveryFileOfAFolder() throws {
        let folder = try TemporaryFolder()
        let files = try (0..<5).map { try folder.makeFile("nested/file\($0).bin", size: 10_000 * ($0 + 1)) }
        let calculator = AllocatedSizeCalculator()

        #expect(calculator.size(of: folder.root) == files.map(calculator.size(of:)).reduce(0, +))
    }

    @Test func stopsMeasuringAFolderWhenTheTaskIsCancelled() async throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("file.bin", size: 10_000)
        let root = folder.root

        let size = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return AllocatedSizeCalculator().size(of: root)
        }.value

        #expect(size == 0)
    }

    @Test func returnsZeroForMissingItems() {
        let missing = URL(filePath: "/nonexistent/\(UUID().uuidString)")
        #expect(AllocatedSizeCalculator().size(of: missing) == 0)
    }
}
