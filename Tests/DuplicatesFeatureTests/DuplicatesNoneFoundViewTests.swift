import CleanMacUI
@testable import DuplicatesFeature
import Foundation
import Testing

@MainActor
struct DuplicatesNoneFoundViewTests {
    private let downloads = URL(filePath: "/Users/test/Downloads")

    private func subtitle(minimumSize: Int64, folder: URL? = nil) -> String {
        DuplicatesNoneFoundView(
            wasStoppedEarly: false,
            minimumSize: minimumSize,
            folder: folder,
            theme: .neutral,
            onScanAgain: {}
        ).subtitle
    }

    @Test func tellsTheSmallestSizeTheScanCompared() {
        let size = Int64(10_000_000).formattedByteCount

        #expect(subtitle(minimumSize: 10_000_000).contains(size))
        #expect(subtitle(minimumSize: 10_000_000, folder: downloads).contains(size))
    }
}
