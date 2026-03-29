import Foundation

final class AppBootstrapper {
    private let defaults: UserDefaults
    private let languageCodeKey = "AppLanguageCode"
    private let defaultLanguageCode = "en"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func prepare() {
        _ = CoreDataStack.shared
        CacheSettings.shared.apply()
        applyPreferredLanguage()
    }

    private func applyPreferredLanguage() {
        let languageCode = defaults.string(forKey: languageCodeKey) ?? defaultLanguageCode

        if defaults.string(forKey: languageCodeKey) == nil {
            defaults.set(languageCode, forKey: languageCodeKey)
        }

        defaults.set([languageCode], forKey: "AppleLanguages")
    }
}
