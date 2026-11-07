import Testing

/// Every String Catalog must be fully translated to Spanish and in sync with the code.
struct TranslationCoverageTests {
    static let catalogs = CatalogLocator.catalogs()

    @Test func findsTheCatalogOfEveryLocalizedModule() {
        #expect(Self.catalogs.count >= 3)
    }

    @Test(arguments: catalogs)
    func usesEnglishAsSourceLanguage(_ file: CatalogFile) throws {
        #expect(try file.load().sourceLanguage == "en")
    }

    @Test(arguments: catalogs)
    func translatesEveryKeyToSpanish(_ file: CatalogFile) throws {
        let catalog = try file.load()
        let untranslated = catalog.activeKeys.filter { key in
            catalog.strings[key]?.localization(for: "es")?.isTranslated != true
        }
        #expect(untranslated.isEmpty, "Missing Spanish translations: \(untranslated)")
    }

    @Test(arguments: catalogs)
    func hasNoStaleKeys(_ file: CatalogFile) throws {
        let stale = try file.load().staleKeys
        #expect(stale.isEmpty, "Unused keys, run `make strings` and remove them: \(stale)")
    }

    @Test(arguments: catalogs)
    func pluralizesEnglishWheneverSpanishIsPluralized(_ file: CatalogFile) throws {
        let catalog = try file.load()
        let missingEnglishPlural = catalog.activeKeys.filter { key in
            guard let entry = catalog.strings[key],
                  entry.localization(for: "es")?.hasPluralVariations == true else {
                return false
            }
            return entry.localization(for: "en")?.hasPluralVariations != true
        }
        #expect(missingEnglishPlural.isEmpty, "Spanish has plurals but English does not: \(missingEnglishPlural)")
    }
}
