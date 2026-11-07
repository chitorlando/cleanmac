/// File name prepared for matching: lowercased and without a known Library extension,
/// so "com.Foo.App.plist" compares equal to "com.foo.app".
struct LeftoverName {
    private static let strippedExtensions: Set<String> = ["plist", "savedstate", "binarycookies"]

    let value: String

    init(_ fileName: String) {
        let lowercased = fileName.lowercased()
        guard
            let dot = lowercased.lastIndex(of: "."),
            Self.strippedExtensions.contains(String(lowercased[lowercased.index(after: dot)...]))
        else {
            value = lowercased
            return
        }
        value = String(lowercased[..<dot])
    }
}
