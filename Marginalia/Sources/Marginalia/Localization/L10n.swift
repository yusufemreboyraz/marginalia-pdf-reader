import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case en
    case tr

    var id: String { rawValue }

    var label: String {
        switch self {
        case .en: return "English"
        case .tr: return "Türkçe"
        }
    }

    /// Resolves the active language from UserDefaults (defaults to English).
    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.en.rawValue
        return AppLanguage(rawValue: raw) ?? .en
    }
}

/// Look up a localized string from the bundled .lproj that matches the user's
/// chosen `AppLanguage`. Falls back to English if a key is missing.
func L(_ key: String) -> String {
    let lang = AppLanguage.current

    if let path = Bundle.module.path(forResource: lang.rawValue, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let value = bundle.localizedString(forKey: key, value: "__missing__", table: nil)
        if value != "__missing__" { return value }
    }

    if lang != .en,
       let path = Bundle.module.path(forResource: AppLanguage.en.rawValue, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    return key
}

/// Convenience for format-string keys (e.g. "Page %d / %d").
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = L(key)
    guard !args.isEmpty else { return format }
    return String(format: format, locale: Locale(identifier: AppLanguage.current.rawValue), arguments: args)
}
