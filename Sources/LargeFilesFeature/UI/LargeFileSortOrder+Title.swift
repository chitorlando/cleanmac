import Foundation

extension LargeFileSortOrder {
    var title: String {
        switch self {
        case .size:
            String(localized: "Size", bundle: .module, comment: "Sort option and filter title: how much space a file takes up.")
        case .name:
            String(localized: "Name", bundle: .module, comment: "Sort option: alphabetical order.")
        case .lastAccess:
            String(localized: "Last Used", bundle: .module, comment: "Sort option and filter title: when a file was last opened.")
        }
    }
}
