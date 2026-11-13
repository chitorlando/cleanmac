import CryptoKit
import Foundation

// Validates the final update's signature, metadata and download links before
// publication. This also catches a CI secret that differs from the app's key.
let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    fatalError("Usage: verify-update.swift Info.plist release-directory vVERSION")
}
let plistURL = URL(fileURLWithPath: arguments[1])
let directory = URL(fileURLWithPath: arguments[2], isDirectory: true)
let tag = arguments[3]

func require(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw NSError(domain: "CleanMac.Release", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

do {
    let plist = try PropertyListSerialization.propertyList(
        from: Data(contentsOf: plistURL), format: nil
    ) as! [String: Any]
    let publicKey = try Curve25519.Signing.PublicKey(
        rawRepresentation: Data(base64Encoded: plist["SUPublicEDKey"] as! String)!
    )
    let document = try XMLDocument(contentsOf: directory.appendingPathComponent("appcast.xml"))
    let items = try document.nodes(forXPath: "/rss/channel/item")
    try require(items.count == 1, "Expected exactly one release in the appcast")
    let item = items[0] as! XMLElement
    let enclosure = item.elements(forName: "enclosure").first!
    let archive = try Data(contentsOf: directory.appendingPathComponent("CleanMac.dmg"))
    let signature = Data(base64Encoded: enclosure.attribute(forName: "sparkle:edSignature")!.stringValue!)!
    try require(publicKey.isValidSignature(signature, for: archive), "Invalid signature for the app's public key")
    try require(enclosure.attribute(forName: "length")?.stringValue == String(archive.count), "Incorrect archive length")
    let prefix = "https://github.com/chitorlando/cleanmac/releases/download/\(tag)/"
    try require(enclosure.attribute(forName: "url")?.stringValue == prefix + "CleanMac.dmg", "Incorrect download URL")
    try require(item.elements(forName: "sparkle:version").first?.stringValue == plist["CFBundleVersion"] as? String, "Incorrect build number")
    try require(item.elements(forName: "sparkle:shortVersionString").first?.stringValue == String(tag.dropFirst()), "Incorrect release version")
    try require(plist["CFBundleShortVersionString"] as? String == String(tag.dropFirst()), "Tag does not match the app")
    let notes = item.elements(forName: "sparkle:releaseNotesLink")
    try require(notes.contains { $0.stringValue == prefix + "CleanMac.html" }, "Missing English release notes")
    try require(notes.contains {
        $0.stringValue == prefix + "CleanMac.es.html" && $0.attribute(forName: "xml:lang")?.stringValue == "es"
    }, "Missing Spanish release notes")
    print("Verified update signature, version, size and localized release notes.")
} catch {
    fputs("Release verification failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
