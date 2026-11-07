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
        title: "Cachés de usuario",
        summary: "Archivos temporales que las apps vuelven a generar cuando los necesitan.",
        symbolName: "archivebox.fill"
    )

    static let userLogs = JunkCategory(
        id: "user-logs",
        title: "Registros de usuario",
        summary: "Historiales de actividad y diagnóstico de las apps.",
        symbolName: "doc.text.fill"
    )

    static let xcodeDerivedData = JunkCategory(
        id: "xcode-derived-data",
        title: "Datos derivados de Xcode",
        summary: "Compilaciones intermedias. Xcode las recrea en la siguiente compilación.",
        symbolName: "hammer.fill"
    )

    static let deviceSupport = JunkCategory(
        id: "device-support",
        title: "Soporte de dispositivos",
        summary: "Símbolos de depuración de versiones antiguas de iOS, watchOS y tvOS.",
        symbolName: "iphone.gen3"
    )

    static let simulatorCaches = JunkCategory(
        id: "simulator-caches",
        title: "Cachés de simuladores",
        summary: "Datos temporales de los simuladores de Xcode.",
        symbolName: "macbook.and.iphone"
    )
}
