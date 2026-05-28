import SwiftUI

/// Environment value distributing the active theme mode + derived "paper" flag.
struct ThemeContext: Equatable {
    var mode: ThemeMode
    var isPaper: Bool { mode == .paper }
}

private struct ThemeContextKey: EnvironmentKey {
    static let defaultValue = ThemeContext(mode: .system)
}

extension EnvironmentValues {
    var themeContext: ThemeContext {
        get { self[ThemeContextKey.self] }
        set { self[ThemeContextKey.self] = newValue }
    }
}

extension View {
    /// Applies preferred color scheme + a paper-tinted background overlay when the user picks Paper.
    @ViewBuilder
    func mApplyTheme(_ mode: ThemeMode) -> some View {
        self
            .environment(\.themeContext, ThemeContext(mode: mode))
            .preferredColorScheme(mode.colorScheme)
            .background(
                Group {
                    if mode == .paper {
                        Tokens.Paper.background.ignoresSafeArea()
                    }
                }
            )
            .foregroundStyle(mode == .paper ? AnyShapeStyle(Tokens.Paper.ink) : AnyShapeStyle(.primary))
            .tint(Tokens.Brand.ribbon)
    }
}
