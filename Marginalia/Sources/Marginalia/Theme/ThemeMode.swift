import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case paper
    case ivory
    case espresso
    case nocturne
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:   return L("theme.system")
        case .light:    return L("theme.light")
        case .paper:    return L("theme.paper")
        case .ivory:    return L("theme.ivory")
        case .espresso: return L("theme.espresso")
        case .nocturne: return L("theme.nocturne")
        case .dark:     return L("theme.dark")
        }
    }

    var systemImage: String {
        switch self {
        case .system:   return "circle.lefthalf.filled"
        case .light:    return "sun.max"
        case .paper:    return "book.pages"
        case .ivory:    return "leaf"
        case .espresso: return "cup.and.saucer"
        case .nocturne: return "moon.stars"
        case .dark:     return "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light, .paper, .ivory: return .light
        case .dark, .espresso, .nocturne: return .dark
        }
    }

    var isDark: Bool {
        colorScheme == .dark
    }

    /// Cycle through visible themes (skips .system).
    func next() -> ThemeMode {
        switch self {
        case .system:   return .light
        case .light:    return .paper
        case .paper:    return .ivory
        case .ivory:    return .espresso
        case .espresso: return .nocturne
        case .nocturne: return .dark
        case .dark:     return .light
        }
    }

    /// Color that fills the reader's main surface (the area the PDF page sits
    /// on plus the gutter between pages).
    var surface: Color {
        switch self {
        case .light, .system: return Tokens.Reading.lightSurface
        case .paper:          return Tokens.Reading.paperSurface
        case .ivory:          return Tokens.Reading.ivorySurface
        case .espresso:       return Tokens.Reading.espressoSurface
        case .nocturne:       return Tokens.Reading.nocturneSurface
        case .dark:           return Tokens.Reading.darkSurface
        }
    }

    /// Multiply tint applied to the PDF output. For dark themes this is the
    /// cream that the (inverted) white text becomes. For light themes it
    /// shifts the white page toward a warmer / cooler paper feel.
    var ink: Color {
        switch self {
        case .light, .system: return .white
        case .paper:          return Tokens.Reading.paperSurface
        case .ivory:          return Tokens.Reading.ivorySurface
        case .espresso:       return Tokens.Reading.warmCream
        case .nocturne:       return Tokens.Reading.coolCream
        case .dark:           return Tokens.Reading.plainCream
        }
    }

    /// Text color used in Reflow mode (when we render extracted PDF text
    /// ourselves and have full color control — no PDF filter math involved).
    var readingInk: Color {
        switch self {
        case .light, .system: return Color(.sRGB, red: 0.13, green: 0.12, blue: 0.11, opacity: 1.0)
        case .paper:          return Tokens.Paper.ink
        case .ivory:          return Color(.sRGB, red: 0.20, green: 0.18, blue: 0.15, opacity: 1.0)
        case .espresso:       return Tokens.Reading.warmCream
        case .nocturne:       return Tokens.Reading.coolCream
        case .dark:           return Tokens.Reading.plainCream
        }
    }

    /// Secondary / muted text color (page numbers, chapter labels) in Reflow mode.
    var readingInkSecondary: Color {
        readingInk.opacity(0.55)
    }
}
