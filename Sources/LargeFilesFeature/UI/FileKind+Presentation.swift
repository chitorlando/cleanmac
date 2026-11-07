import Foundation

extension FileKind {
    var title: String {
        switch self {
        case .archive:
            String(localized: "Archives", bundle: .module, comment: "File kind filter: zip, tar and other compressed files.")
        case .diskImage:
            String(localized: "Disk Images", bundle: .module, comment: "File kind filter: dmg and iso files.")
        case .video:
            String(localized: "Videos", bundle: .module, comment: "File kind filter.")
        case .audio:
            String(localized: "Audio", bundle: .module, comment: "File kind filter: music, podcasts and recordings.")
        case .image:
            String(localized: "Images", bundle: .module, comment: "File kind filter: photos and pictures.")
        case .document:
            String(localized: "Documents", bundle: .module, comment: "File kind filter: PDF, text, spreadsheets and presentations.")
        case .other:
            String(localized: "Other", bundle: .module, comment: "File kind filter: files of any other kind.")
        }
    }

    var symbolName: String {
        switch self {
        case .archive: "doc.zipper"
        case .diskImage: "externaldrive.fill"
        case .video: "film.fill"
        case .audio: "music.note"
        case .image: "photo.fill"
        case .document: "doc.text.fill"
        case .other: "doc.fill"
        }
    }
}
