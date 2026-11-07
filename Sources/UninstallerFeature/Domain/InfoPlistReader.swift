import Foundation

/// `AppInfoReading` that parses `Contents/Info.plist` directly, without loading the bundle.
public struct InfoPlistReader: AppInfoReading {
    public init() {}

    public func info(forAppAt url: URL) -> AppBundleInfo? {
        guard
            let plist = properties(ofAppAt: url),
            let bundleID = nonEmptyString(plist["CFBundleIdentifier"])
        else { return nil }

        let name = url.deletingPathExtension().lastPathComponent
        return AppBundleInfo(
            url: url,
            bundleID: bundleID,
            name: name,
            version: nonEmptyString(plist["CFBundleShortVersionString"]),
            alternateNames: alternateNames(in: plist, excluding: name)
        )
    }

    private func properties(ofAppAt url: URL) -> [String: Any]? {
        let plistURL = url.appending(path: "Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL) else { return nil }
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        return plist as? [String: Any]
    }

    private func alternateNames(in plist: [String: Any], excluding name: String) -> [String] {
        var seen: Set<String> = [name.lowercased()]
        return ["CFBundleName", "CFBundleDisplayName"]
            .compactMap { nonEmptyString(plist[$0]) }
            .filter { seen.insert($0.lowercased()).inserted }
    }

    private func nonEmptyString(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return string
    }
}
