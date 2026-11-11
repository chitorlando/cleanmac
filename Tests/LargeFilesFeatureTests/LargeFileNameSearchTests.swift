@testable import LargeFilesFeature
import Testing

struct LargeFileNameSearchTests {
    private let song = LargeFileFixtures.file("Canción de verano.mp3", folder: "/Users/test/Music", megabytes: 60)

    @Test(arguments: ["canción", "CANCION", "verano.MP3", "  de verano  "])
    func findsTheTextIgnoringCaseAccentsAndTheSpacesAroundIt(text: String) {
        #expect(LargeFileNameSearch(text).matches(song))
    }

    @Test(arguments: ["", "   ", "\n"])
    func matchesEveryFileWithoutText(text: String) {
        #expect(LargeFileNameSearch(text).matches(song))
    }

    @Test func looksOnlyAtTheNameOfTheFile() {
        #expect(!LargeFileNameSearch("music").matches(song))
        #expect(!LargeFileNameSearch("invierno").matches(song))
    }
}
