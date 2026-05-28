import SwiftUI

/// Design tokens. Colors are sRGB approximations of OKLCH targets defined in the shape brief.
enum Tokens {
    enum Brand {
        /// Ribbon / accent color. oklch(0.42 0.09 30) ≈ deep red-brown.
        static let ribbon = Color(.sRGB, red: 0.486, green: 0.278, blue: 0.220, opacity: 1.0)
        /// Slightly lighter for hover / highlight fill.
        static let ribbonSoft = Color(.sRGB, red: 0.486, green: 0.278, blue: 0.220, opacity: 0.18)
    }

    enum Paper {
        /// Background — oklch(0.94 0.02 75) ≈ warm cream.
        static let background = Color(.sRGB, red: 0.957, green: 0.918, blue: 0.855, opacity: 1.0)
        /// Secondary surface — slightly darker cream.
        static let surface = Color(.sRGB, red: 0.925, green: 0.882, blue: 0.812, opacity: 1.0)
        /// Primary ink — oklch(0.28 0.02 60).
        static let ink = Color(.sRGB, red: 0.306, green: 0.267, blue: 0.212, opacity: 1.0)
        static let inkSecondary = Color(.sRGB, red: 0.408, green: 0.365, blue: 0.302, opacity: 1.0)
    }

    /// Per-theme reading palette. `surface` is what fills the page area (and the
    /// gutter between pages); `ink` is the cream/tint applied to the rendered
    /// text via `.colorMultiply` after inversion. For light themes `ink` is the
    /// multiply tint applied directly to the un-inverted page.
    enum Reading {
        static let lightSurface  = Color(.sRGB, red: 1.000, green: 1.000, blue: 1.000, opacity: 1.0)
        static let paperSurface  = Color(.sRGB, red: 0.957, green: 0.918, blue: 0.855, opacity: 1.0)
        static let ivorySurface  = Color(.sRGB, red: 0.984, green: 0.973, blue: 0.945, opacity: 1.0)

        /// Warm espresso brown — like a strong coffee bean.
        static let espressoSurface = Color(.sRGB, red: 0.235, green: 0.196, blue: 0.165, opacity: 1.0)
        /// Deep slate-navy — like the sky right before dawn.
        static let nocturneSurface = Color(.sRGB, red: 0.110, green: 0.133, blue: 0.180, opacity: 1.0)
        /// Near-black with the faintest warm tint.
        static let darkSurface     = Color(.sRGB, red: 0.082, green: 0.078, blue: 0.075, opacity: 1.0)

        /// Cream tint for text in dark themes. Multiplied with inverted PDF output.
        static let warmCream  = Color(.sRGB, red: 0.945, green: 0.918, blue: 0.875, opacity: 1.0)
        static let coolCream  = Color(.sRGB, red: 0.918, green: 0.929, blue: 0.945, opacity: 1.0)
        static let plainCream = Color(.sRGB, red: 0.953, green: 0.945, blue: 0.929, opacity: 1.0)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 40
    }

    enum Radius {
        static let s: CGFloat = 4
        static let m: CGFloat = 8
        static let l: CGFloat = 12
    }

    enum FontSize {
        static let caption: CGFloat = 12
        static let body: CGFloat = 15
        static let title: CGFloat = 19
        static let display: CGFloat = 28
    }
}

extension Font {
    static let mUIBody    = Font.system(size: Tokens.FontSize.body, weight: .regular, design: .default)
    static let mUICaption = Font.system(size: Tokens.FontSize.caption, weight: .regular, design: .default)
    static let mUITitle   = Font.system(size: Tokens.FontSize.title, weight: .semibold, design: .default)
    static let mReadTitle = Font.system(size: Tokens.FontSize.display, weight: .semibold, design: .serif)
    static let mReadBody  = Font.system(size: Tokens.FontSize.body, weight: .regular, design: .serif)
}
