import CleanMacCore
import Foundation

/// Every junk category CleanMac knows about and where to find it.
public enum JunkCatalog {
    public static func scanners(
        home: URL,
        reader: any DirectoryReading,
        sizer: any SizeCalculating
    ) -> [any JunkScanner] {
        entries(home: home).map { category, locations in
            DirectoryJunkScanner(
                category: category,
                locations: locations,
                reader: reader,
                sizer: sizer
            )
        }
    }

    private static func entries(home: URL) -> [(JunkCategory, [URL])] {
        let library = home.appending(path: "Library")
        let developer = library.appending(path: "Developer")
        return [
            (.userCaches, [library.appending(path: "Caches")]),
            (.userLogs, [library.appending(path: "Logs")]),
            (.xcodeDerivedData, [developer.appending(path: "Xcode/DerivedData")]),
            (.deviceSupport, [
                developer.appending(path: "Xcode/iOS DeviceSupport"),
                developer.appending(path: "Xcode/watchOS DeviceSupport"),
                developer.appending(path: "Xcode/tvOS DeviceSupport")
            ]),
            (.simulatorCaches, [developer.appending(path: "CoreSimulator/Caches")])
        ]
    }
}

public extension JunkCategory {
    static let userCaches = JunkCategory(
        id: "user-caches",
        title: String(localized: "User Caches", bundle: .module, comment: "Junk category title."),
        summary: String(
            localized: "Temporary files apps recreate when they need them.",
            bundle: .module,
            comment: "Description of the user caches junk category."
        ),
        symbolName: "archivebox.fill"
    )

    static let userLogs = JunkCategory(
        id: "user-logs",
        title: String(localized: "User Logs", bundle: .module, comment: "Junk category title."),
        summary: String(
            localized: "Activity and diagnostic history kept by apps.",
            bundle: .module,
            comment: "Description of the user logs junk category."
        ),
        symbolName: "doc.text.fill"
    )

    static let xcodeDerivedData = JunkCategory(
        id: "xcode-derived-data",
        title: String(localized: "Xcode Derived Data", bundle: .module, comment: "Junk category title."),
        summary: String(
            localized: "Intermediate build files. Xcode recreates them on the next build.",
            bundle: .module,
            comment: "Description of the Xcode derived data junk category."
        ),
        symbolName: "hammer.fill"
    )

    static let deviceSupport = JunkCategory(
        id: "device-support",
        title: String(localized: "Device Support", bundle: .module, comment: "Junk category title."),
        summary: String(
            localized: "Debug symbols for older iOS, watchOS and tvOS versions.",
            bundle: .module,
            comment: "Description of the device support junk category."
        ),
        symbolName: "iphone.gen3"
    )

    static let simulatorCaches = JunkCategory(
        id: "simulator-caches",
        title: String(localized: "Simulator Caches", bundle: .module, comment: "Junk category title."),
        summary: String(
            localized: "Temporary data from the Xcode simulators.",
            bundle: .module,
            comment: "Description of the simulator caches junk category."
        ),
        symbolName: "macbook.and.iphone"
    )
}
