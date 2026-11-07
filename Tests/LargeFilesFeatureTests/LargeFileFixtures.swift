import CleanMacCore
import Foundation
import LargeFilesFeature

/// Builders for large files and fixed dates shared by the presentation tests.
enum LargeFileFixtures {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static let now = date(2026, 11, 7)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func file(
        _ name: String,
        folder: String = "/Users/test",
        megabytes: Int64,
        lastUsed: Date? = now,
        kind: FileKind? = nil
    ) -> LargeFile {
        let url = URL(filePath: folder).appending(path: name)
        return LargeFile(
            item: CleanableItem(url: url, size: megabytes * 1_000_000),
            kind: kind ?? FileKind(url: url),
            lastAccessDate: lastUsed
        )
    }
}
