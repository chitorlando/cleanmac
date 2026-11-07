import Foundation
import LargeFilesFeature
import Testing

struct FileKindTests {
    @Test(arguments: [
        ("backup.zip", FileKind.archive),
        ("sources.tar.gz", .archive),
        ("Installer.dmg", .diskImage),
        ("ubuntu.iso", .diskImage),
        ("holidays.mov", .video),
        ("clip.mp4", .video),
        ("song.mp3", .audio),
        ("voice.m4a", .audio),
        ("photo.jpg", .image),
        ("photo.heic", .image),
        ("manual.pdf", .document),
        ("report.docx", .document),
        ("budget.xlsx", .document),
        ("slides.pptx", .document),
        ("notes.txt", .document),
        ("data.xyz", .other),
        ("no-extension", .other)
    ])
    func classifiesByExtension(name: String, kind: FileKind) {
        #expect(FileKind(url: URL(filePath: "/tmp/\(name)")) == kind)
    }
}
