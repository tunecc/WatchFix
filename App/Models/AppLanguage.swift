import Foundation

enum AppLanguage: String, CaseIterable {
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"

    static var current: AppLanguage {
        AppLanguage(rawValue: WFCurrentPreferredAppLanguageIdentifier()) ?? .simplifiedChinese
    }

    var nativeDisplayName: String {
        switch self {
        case .simplifiedChinese:
            return "简体中文"
        case .traditionalChinese:
            return "繁體中文"
        case .english:
            return "English"
        }
    }

    func persistSelection() {
        WFSetPreferredAppLanguageIdentifier(rawValue)
    }
}

enum AppLocalization {
    static func localizedString(in bundle: Bundle, key: String, fallback: String? = nil) -> String {
        let language = AppLanguage.current.rawValue
        for candidate in [language, "en"] {
            guard let path = bundle.path(forResource: candidate, ofType: "lproj"),
                  let localizedBundle = Bundle(path: path) else {
                continue
            }

            let localized = localizedBundle.localizedString(forKey: key, value: nil, table: nil)
            if localized != key {
                return localized
            }
        }

        let bundledValue = bundle.localizedString(forKey: key, value: nil, table: nil)
        if bundledValue != key {
            return bundledValue
        }

        return fallback ?? key
    }
}
