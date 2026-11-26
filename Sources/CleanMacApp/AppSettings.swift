import CleanMacCore

/// What the user can choose about the app as a whole.
enum AppSettings {
    /// Language of the app.
    ///
    /// Kept under the key macOS reads an app's languages from when it starts, the one
    /// System Settings writes for the language of a single app. A choice takes effect at the
    /// next launch, and the system's choice, being the default, is kept by keeping nothing.
    static let language = Setting(key: "AppleLanguages", defaultValue: AppLanguage.system, allowedValues: AppLanguage.allCases)
}
