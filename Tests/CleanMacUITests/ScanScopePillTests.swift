import CleanMacUI
import Foundation
import Testing

@MainActor
struct ScanScopePillTests {
    private let downloads = URL(filePath: "/Users/test/Downloads")
    private let movies = URL(filePath: "/Users/test/Movies")

    private func pill(_ folder: URL, theme: FeatureTheme = .duplicates) -> ScanScopePill {
        ScanScopePill(folder: folder, theme: theme) {}
    }

    @Test func pillsOfTheSameFolderAndThemeAreEqualWhateverTheirAction() {
        #expect(pill(downloads) == pill(downloads))
    }

    @Test func pillsOfDifferentFoldersOrThemesAreDifferent() {
        #expect(pill(downloads) != pill(movies))
        #expect(pill(downloads) != pill(downloads, theme: .largeFiles))
    }

    @Test func thePathOfAFolderOfTheHomeStartsWithATilde() {
        let home = FileManager.default.homeDirectoryForCurrentUser

        #expect(home.appending(path: "Downloads").tildeAbbreviatedPath == "~/Downloads")
        #expect(URL(filePath: "/Applications").tildeAbbreviatedPath == "/Applications")
    }
}
