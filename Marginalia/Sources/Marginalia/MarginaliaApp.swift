import SwiftUI

@main
struct MarginaliaApp: App {
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.system.rawValue
    @AppStorage("appLanguage") private var languageRaw: String = AppLanguage.en.rawValue
    @State private var store = LibraryStore()

    private var themeMode: ThemeMode { ThemeMode(rawValue: themeModeRaw) ?? .system }

    var body: some Scene {
        // Main library window — always uses the system appearance. The reading
        // theme (Paper/Dark) is intentionally scoped to the reader window so
        // browsing the library doesn't get tinted while you're picking a book.
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Tokens.Brand.ribbon)
                .frame(minWidth: 900, minHeight: 600)
                .id(languageRaw)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands { commands }

        // Reader window — opened per book via openWindow(value: bookID).
        // Each unique bookID gets its own clean focused window; reopening the
        // same book just brings its window forward.
        WindowGroup(id: "reader", for: UUID.self) { $bookID in
            Group {
                if let id = bookID {
                    ReaderHost(bookID: id)
                        .environment(store)
                        .mApplyTheme(themeMode)
                        .frame(minWidth: 600, minHeight: 700)
                        .id(languageRaw)
                } else {
                    Color.clear
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .defaultSize(width: 900, height: 1100)
    }

    @CommandsBuilder
    private var commands: some Commands {
        CommandGroup(after: .appSettings) {
            Menu(L("menu.theme")) {
                ForEach(ThemeMode.allCases) { mode in
                    Button {
                        themeModeRaw = mode.rawValue
                    } label: {
                        Label(mode.label, systemImage: mode.systemImage)
                    }
                    .keyboardShortcut(shortcut(for: mode))
                }
            }
            Button(L("menu.next_theme")) {
                themeModeRaw = themeMode.next().rawValue
            }
            .keyboardShortcut("l", modifiers: [.command])

            Menu(L("menu.language")) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        languageRaw = lang.rawValue
                    } label: {
                        HStack {
                            Text(lang.label)
                            if lang.rawValue == languageRaw {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    private func shortcut(for mode: ThemeMode) -> KeyboardShortcut? {
        // Only the system theme gets a stable shortcut — for the rest the user
        // can cycle with ⌘L. (Reserving 6+ keys clutters the menu, and macOS
        // already mediates ⌘⌥<digit> for native commands in many apps.)
        switch mode {
        case .system: return KeyboardShortcut("0", modifiers: [.command, .option])
        case .light, .paper, .ivory, .espresso, .nocturne, .dark: return nil
        }
    }
}
