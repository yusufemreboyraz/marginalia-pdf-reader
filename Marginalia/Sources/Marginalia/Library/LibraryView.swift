import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    let scope: LibraryScope
    @Binding var searchText: String

    @Environment(LibraryStore.self) private var store

    @State private var sortKey: SortKey = .addedAt
    @State private var viewMode: ViewMode = .grid
    @State private var isImporterPresented = false
    @State private var importError: String?

    enum SortKey: String, CaseIterable, Identifiable {
        case addedAt, title, author, progress
        var id: String { rawValue }
        var label: String {
            switch self {
            case .addedAt:  return L("sort.added")
            case .title:    return L("sort.title")
            case .author:   return L("sort.author")
            case .progress: return L("sort.progress")
            }
        }
    }

    enum ViewMode: String, CaseIterable, Identifiable {
        case grid, list
        var id: String { rawValue }
        var systemImage: String { self == .grid ? "square.grid.2x2" : "list.bullet" }
    }

    var filtered: [Book] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return store.books
            .filter { book in
                switch scope {
                case .all: return true
                case .status(let s): return book.status == s
                case .category(let id): return book.categoryIDs.contains(id)
                }
            }
            .filter { book in
                guard !query.isEmpty else { return true }
                if book.title.lowercased().contains(query) { return true }
                if book.author.lowercased().contains(query) { return true }
                let hls = store.highlights(for: book)
                if hls.contains(where: {
                    $0.selectedText.lowercased().contains(query) ||
                    $0.note.lowercased().contains(query)
                }) { return true }
                return false
            }
            .sorted(by: sortComparator)
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                EmptyLibraryView(isImporterPresented: $isImporterPresented)
            } else {
                content
            }
        }
        .navigationTitle(scope.title)
        .toolbar { toolbar }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true,
            onCompletion: handleImport
        )
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        .alert(
            Text(L("error.import_title")),
            isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })
        ) {
            Button(L("common.ok"), role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewMode {
        case .grid:
            ScrollView {
                CoverGrid(books: filtered)
                    .padding(.horizontal, Tokens.Spacing.xl)
                    .padding(.vertical, Tokens.Spacing.l)
            }
        case .list:
            List(filtered) { book in
                NavigationLink(value: book) {
                    BookListRow(book: book)
                }
            }
            .listStyle(.inset)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                isImporterPresented = true
            } label: {
                Label(L("library.import_short"), systemImage: "plus")
            }
            .keyboardShortcut("o", modifiers: [.command])
        }
        ToolbarItem(placement: .secondaryAction) {
            Picker(L("library.sort"), selection: $sortKey) {
                ForEach(SortKey.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.menu)
        }
        ToolbarItem(placement: .secondaryAction) {
            Picker(L("library.view"), selection: $viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Image(systemName: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var sortComparator: (Book, Book) -> Bool {
        switch sortKey {
        case .addedAt:  return { $0.addedAt > $1.addedAt }
        case .title:    return { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:   return { $0.author.localizedCompare($1.author) == .orderedAscending }
        case .progress: return { $0.progress > $1.progress }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    try BookImporter.import(from: url, into: store)
                } catch {
                    importError = error.localizedDescription
                }
            }
        case .failure(let err):
            importError = err.localizedDescription
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    Task { @MainActor in
                        do {
                            try BookImporter.import(from: url, into: store)
                        } catch {
                            importError = error.localizedDescription
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }
}

private struct BookListRow: View {
    let book: Book
    var body: some View {
        HStack(spacing: Tokens.Spacing.m) {
            CoverImage(book: book)
                .frame(width: 36, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.s))
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title).font(.mUIBody).lineLimit(1)
                Text(book.author.isEmpty ? "—" : book.author)
                    .font(.mUICaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if book.status == .reading {
                Text("\(Int(book.progress * 100))%")
                    .font(.mUICaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: book.status.systemImage)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyLibraryView: View {
    @Binding var isImporterPresented: Bool
    var body: some View {
        VStack(spacing: Tokens.Spacing.l) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            VStack(spacing: Tokens.Spacing.s) {
                Text(L("library.empty.title"))
                    .font(.mUITitle)
                Text(L("library.empty.body"))
                    .font(.mUIBody)
                    .foregroundStyle(.secondary)
            }
            Button {
                isImporterPresented = true
            } label: {
                Label(L("library.import"), systemImage: "plus")
                    .frame(minWidth: 160)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(Tokens.Brand.ribbon)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
