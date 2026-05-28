import SwiftUI
import PDFKit
import AppKit

struct ReaderView: View {
    @Bindable var book: Book
    let dismiss: () -> Void

    @Environment(LibraryStore.self) private var store
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.system.rawValue

    @AppStorage("readerTwoUp") private var twoUp: Bool = true
    @AppStorage("readerReflow") private var reflow: Bool = true   // default to the Apple Books-like view

    @State private var document: PDFDocument?
    @State private var extractedPages: [ExtractedPage] = []
    @State private var loadError: String?
    @State private var chromeVisible: Bool = true
    @State private var idleTask: Task<Void, Never>?
    @State private var selection: PDFSelection?
    @State private var showNotes: Bool = false
    @State private var controller = PDFController()

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()

            if let document {
                if reflow {
                    ReflowView(
                        pages: extractedPages,
                        bookTitle: book.title,
                        themeMode: themeMode,
                        currentPage: Binding(
                            get: { book.currentPage },
                            set: { newValue in
                                book.currentPage = newValue
                                book.lastOpenedAt = .now
                                if book.status == .unread && newValue > 0 {
                                    book.status = .reading
                                }
                                store.touch()
                            }
                        )
                    )
                } else {
                    themedPDF(document: document)
                }
            } else if loadError != nil {
                VStack(spacing: Tokens.Spacing.m) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text(loadError ?? "")
                        .font(.mUIBody)
                        .foregroundStyle(.secondary)
                    Button(L("common.go_back"), action: dismiss)
                        .keyboardShortcut(.cancelAction)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView().controlSize(.large)
            }

            chromeOverlay
                .opacity(chromeVisible ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: chromeVisible)

            HStack {
                Spacer()
                if showNotes {
                    NotesPanel(book: book, jumpToPage: { jump(to: $0) })
                        .frame(width: 320)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.smooth(duration: 0.25), value: showNotes)

            progressBar
        }
        .task(id: book.id) { await loadDocument() }
        .onContinuousHover { _ in resetIdleTimer() }
        .onAppear { resetIdleTimer() }
        .onDisappear { idleTask?.cancel() }
        .focusable()
        .focusEffectDisabled()
        .background {
            Color.clear
                .onKeyPress(.leftArrow) { advance(by: -1); return .handled }
                .onKeyPress(.rightArrow) { advance(by: +1); return .handled }
                .onKeyPress(.space) { advance(by: +1); return .handled }
                .onKeyPress(.escape) { dismiss(); return .handled }
        }
    }

    private var background: some View {
        themeMode.surface
    }

    /// PDF rendering wrapped in SwiftUI color modifiers. PDFKit draws into
    /// private sub-layers that CALayer filters cannot reach, but SwiftUI's
    /// `colorInvert` / `colorMultiply` / `blendMode(.screen)` operate on the
    /// rasterized NSViewRepresentable output — so the *page itself* (paper +
    /// ink) actually takes on the theme.
    ///
    /// **Every theme** is rendered as `surface (ZStack base) → PDF on top`.
    /// PDFView is transparent (`.clear` background), so the gutter, page
    /// shadows and any chrome PDFKit paints all disappear into the single
    /// uniform surface color — page edge and background look like one piece
    /// of paper, not a page floating on a tray.
    ///
    /// - **Light / System**: PDF rendered as-is on the surface.
    /// - **Paper / Ivory**: multiply with surface color so the page warms up
    ///   to match. Black ink stays black (black × any = black).
    /// - **Dark / Espresso / Nocturne**: invert the PDF (white→black,
    ///   black→white), multiply by ink (so white text becomes warm cream),
    ///   then screen-blend over surface. Screen turns the now-black
    ///   background transparent (revealing surface) and leaves cream text on top.
    @ViewBuilder
    private func themedPDF(document: PDFDocument) -> some View {
        let base = PDFViewRepresentable(
            document: document,
            currentPage: Binding(
                get: { book.currentPage },
                set: { newValue in
                    book.currentPage = newValue
                    book.lastOpenedAt = .now
                    if book.status == .unread && newValue > 0 {
                        book.status = .reading
                    }
                    if book.pageCount > 0 && newValue >= book.pageCount - 1 {
                        book.status = .finished
                    }
                    store.touch()
                }
            ),
            highlights: store.highlights(for: book),
            onSelectionChange: { selection = $0 },
            twoUp: twoUp,
            controller: controller
        )

        ZStack {
            themeMode.surface.ignoresSafeArea()

            Group {
                if themeMode.isDark {
                    // Dark/Espresso/Nocturne: invert → recolor text → screen
                    // blend so the (now-black) page background becomes the
                    // theme surface, leaving only cream ink on top.
                    base
                        .compositingGroup()
                        .colorInvert()
                        .colorMultiply(themeMode.ink)
                        .blendMode(.screen)
                } else if themeMode == .paper || themeMode == .ivory {
                    // Paper/Ivory: just multiply ink. PDFView's page (white)
                    // becomes the theme surface; black text stays black.
                    // NO .blendMode(.multiply) — that would double-multiply
                    // with the surface behind and tint the page darker than
                    // its surroundings, recreating the very tile-on-tray look
                    // we're trying to kill.
                    base
                        .compositingGroup()
                        .colorMultiply(themeMode.ink)
                } else {
                    base
                }
            }
        }
    }

    private var chromeOverlay: some View {
        VStack(spacing: 0) {
            HStack(spacing: Tokens.Spacing.m) {
                // The reader lives in its own clean window now — closing happens
                // via ⌘W (system) or Esc. No "back" button needed; the chrome
                // stays minimal so the focus is the page.
                Spacer()

                VStack(spacing: 0) {
                    Text(book.title)
                        .font(.mUIBody)
                        .lineLimit(1)
                    if book.pageCount > 0 {
                        Text(L("reader.page_format", book.currentPage + 1, book.pageCount))
                            .font(.mUICaption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    addHighlight()
                } label: {
                    Label(L("reader.highlight"), systemImage: "highlighter")
                }
                .disabled(selection?.string?.isEmpty ?? true)
                .keyboardShortcut("h", modifiers: [.command])

                Button {
                    addBookmark()
                } label: {
                    Label(L("reader.bookmark"), systemImage: "bookmark")
                }
                .keyboardShortcut("b", modifiers: [.command])

                Button {
                    reflow.toggle()
                } label: {
                    Label(L(reflow ? "reader.show_original" : "reader.show_reflow"),
                          systemImage: reflow ? "doc.richtext" : "text.alignleft")
                }
                .keyboardShortcut("r", modifiers: [.command])
                .help(L(reflow ? "reader.show_original" : "reader.show_reflow"))

                if !reflow {
                    Button {
                        twoUp.toggle()
                    } label: {
                        Label(L(twoUp ? "reader.single_page" : "reader.two_page"),
                              systemImage: twoUp ? "doc.text" : "book.pages")
                    }
                    .keyboardShortcut("d", modifiers: [.command])
                    .help(L(twoUp ? "reader.single_page" : "reader.two_page"))
                }

                Menu {
                    ForEach(ThemeMode.allCases) { mode in
                        Button {
                            themeModeRaw = mode.rawValue
                        } label: {
                            Label(mode.label, systemImage: mode.systemImage)
                        }
                    }
                } label: {
                    Label(L("reader.theme"), systemImage: themeMode.systemImage)
                }
                .menuStyle(.borderlessButton)

                Button {
                    showNotes.toggle()
                } label: {
                    Label(L("reader.notes"), systemImage: showNotes ? "sidebar.right" : "note.text")
                }
                .keyboardShortcut("2", modifiers: [.command])
            }
            .padding(.horizontal, Tokens.Spacing.l)
            .padding(.vertical, Tokens.Spacing.s)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) {
                Rectangle().fill(.separator).frame(height: 0.5)
            }
            Spacer()
        }
    }

    private var progressBar: some View {
        VStack {
            Spacer()
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Tokens.Brand.ribbon)
                        .frame(width: max(2, CGFloat(book.progress) * proxy.size.width))
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                }
            }
            .frame(height: 1)
        }
        .opacity(chromeVisible ? 0.9 : 0.5)
        .allowsHitTesting(false)
    }

    private func loadDocument() async {
        let url = book.fileURL
        if let doc = PDFDocument(url: url) {
            self.document = doc
            if book.pageCount != doc.pageCount {
                book.pageCount = doc.pageCount
            }
            book.lastOpenedAt = .now
            store.touch()
            // Extract text up-front so toggling Reflow has no perceived delay
            // and search / future text features have something to work on.
            // (PDFDocument is main-actor isolated; extraction is fast enough
            // on the main thread for typical book sizes — moving it off-thread
            // requires Sendable PDFDocument handling we don't need yet.)
            self.extractedPages = PDFTextExtractor.extract(from: doc)
        } else {
            self.loadError = L("reader.could_not_open_format", url.lastPathComponent)
        }
    }

    /// Page navigation. In Reflow mode we update the binding directly so
    /// ReflowView scrolls. In PDF mode we delegate to PDFView (so `.twoUp`
    /// knows to flip two at once).
    private func advance(by delta: Int) {
        if reflow {
            let step = delta > 0 ? 1 : -1
            let next = max(0, min(max(0, book.pageCount - 1), book.currentPage + step))
            if next != book.currentPage {
                book.currentPage = next
                store.touch()
            }
        } else {
            if delta > 0 { controller.next() }
            else if delta < 0 { controller.previous() }
        }
    }

    private func jump(to page: Int) {
        if reflow {
            book.currentPage = max(0, min(max(0, book.pageCount - 1), page))
            store.touch()
        } else {
            controller.go(to: page)
        }
    }

    private func addHighlight() {
        guard let selection, let document,
              let encoded = PDFSelectionEncoder.encode(selection, in: document) else { return }
        let h = Highlight(
            bookID: book.id,
            page: encoded.page,
            selectedText: encoded.text,
            bounds: encoded.data
        )
        store.addHighlight(h)
    }

    private func addBookmark() {
        store.addBookmark(Bookmark(bookID: book.id, page: book.currentPage))
    }

    private func resetIdleTimer() {
        if !chromeVisible {
            chromeVisible = true
        }
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled {
                chromeVisible = false
            }
        }
    }
}
