import Foundation

extension AppItemSection.Category {
    var title: String {
        switch self {
        case .application:
            String(localized: "Application", bundle: .module, comment: "Group that contains the app itself.")
        case .leftover(let kind):
            kind.title
        }
    }
}
