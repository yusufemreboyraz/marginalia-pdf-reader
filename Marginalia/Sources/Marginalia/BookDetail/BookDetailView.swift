import SwiftUI

struct BookDetailView: View {
    @Bindable var book: Book
    let openReader: () -> Void

    @Environment(LibraryStore.self) private var store
    @State private var tab: Tab = .info

    enum Tab: String, CaseIterable, Identifiable {
        case info, notes, highlights
        var id: String { rawValue }
        var label: String {
            switch self {
            case .info:       return L("book.tab.info")
            case .notes:      return L("book.tab.notes")
            case .highlights: return L("book.tab.highlights")
            }
        }
    }

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
            mainColumn
                .frame(minWidth: 400)
        }
        .navigationTitle(book.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openReader()
                } label: {
                    Label(book.currentPage > 0 ? L("book.continue") : L("book.read"), systemImage: "book.fill")
                }
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
            CoverImage(book: book)
                .aspectRatio(2/3, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.m))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(.horizontal, Tokens.Spacing.l)

            VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                TextField(L("book.title_placeholder"), text: $book.title)
                    .textFieldStyle(.plain)
                    .font(.mUITitle)
                    .onChange(of: book.title) { _, _ in store.touch() }
                TextField(L("book.author_placeholder"), text: $book.author)
                    .textFieldStyle(.plain)
                    .font(.mUIBody)
                    .foregroundStyle(.secondary)
                    .onChange(of: book.author) { _, _ in store.touch() }
            }
            .padding(.horizontal, Tokens.Spacing.l)

            RatingView(rating: Binding(
                get: { book.rating },
                set: { book.rating = $0; store.touch() }
            ))
            .padding(.horizontal, Tokens.Spacing.l)

            statusPicker
                .padding(.horizontal, Tokens.Spacing.l)

            progressBlock
                .padding(.horizontal, Tokens.Spacing.l)

            Spacer()
        }
        .padding(.vertical, Tokens.Spacing.l)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.regularMaterial)
    }

    private var statusPicker: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Text(L("book.status")).font(.mUICaption).foregroundStyle(.secondary)
            Picker(L("book.status"), selection: Binding(
                get: { book.status },
                set: { book.status = $0; store.touch() }
            )) {
                ForEach(ReadingStatus.allCases) { s in
                    Label(s.label, systemImage: s.systemImage).tag(s)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Text(L("book.progress")).font(.mUICaption).foregroundStyle(.secondary)
            if book.pageCount > 0 {
                ProgressView(value: book.progress)
                    .tint(Tokens.Brand.ribbon)
                Text(L("reader.page_format", book.currentPage + 1, book.pageCount))
                    .font(.mUICaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text(L("book.not_started"))
                    .font(.mUICaption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { t in
                    Text(t.label).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .padding(Tokens.Spacing.l)

            Divider()

            ScrollView {
                Group {
                    switch tab {
                    case .info:       infoTab
                    case .notes:      notesTab
                    case .highlights: highlightsTab
                    }
                }
                .padding(Tokens.Spacing.l)
            }
        }
    }

    private var infoTab: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
            metaRow(L("book.added"), value: book.addedAt.formatted(date: .abbreviated, time: .omitted))
            if let last = book.lastOpenedAt {
                metaRow(L("book.last_opened"), value: last.formatted(date: .abbreviated, time: .shortened))
            }
            metaRow(L("book.pages"), value: "\(book.pageCount)")
            metaRow(L("book.file"), value: book.fileName)

            VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                Text(L("book.categories")).font(.mUICaption).foregroundStyle(.secondary)
                let sorted = store.categories.sorted { $0.name < $1.name }
                FlowLayout(spacing: 6) {
                    ForEach(sorted) { cat in
                        let isOn = book.categoryIDs.contains(cat.id)
                        Button {
                            toggle(category: cat)
                        } label: {
                            Text(cat.name)
                                .font(.mUICaption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(isOn ? Tokens.Brand.ribbon.opacity(0.18) : Color.secondary.opacity(0.08))
                                )
                                .overlay(
                                    Capsule().stroke(isOn ? Tokens.Brand.ribbon : Color.clear, lineWidth: 0.75)
                                )
                                .foregroundStyle(isOn ? Tokens.Brand.ribbon : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    if sorted.isEmpty {
                        Text(L("book.no_categories"))
                            .font(.mUICaption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            HStack {
                Spacer()
                Button(role: .destructive) {
                    store.deleteBook(book)
                } label: {
                    Label(L("book.remove"), systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, Tokens.Spacing.xl)
        }
    }

    @ViewBuilder
    private var notesTab: some View {
        let withNotes = store.highlights(for: book)
            .filter { $0.hasNote }
            .sorted { $0.createdAt < $1.createdAt }
        if withNotes.isEmpty {
            EmptyTab(message: L("book.notes_empty"))
        } else {
            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                ForEach(withNotes) { h in
                    VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
                        Text(h.selectedText)
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(.secondary)
                        Text(h.note)
                            .font(.mUIBody)
                        HStack {
                            Text(L("notes.page_format", h.page + 1))
                            Spacer()
                            Text(h.createdAt.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.mUICaption)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(Tokens.Spacing.m)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: Tokens.Radius.m))
                }
            }
        }
    }

    @ViewBuilder
    private var highlightsTab: some View {
        let all = store.highlights(for: book).sorted { $0.page < $1.page }
        if all.isEmpty {
            EmptyTab(message: L("book.highlights_empty"))
        } else {
            VStack(alignment: .leading, spacing: Tokens.Spacing.m) {
                ForEach(all) { h in
                    HStack(alignment: .top, spacing: Tokens.Spacing.s) {
                        Rectangle().fill(Tokens.Brand.ribbon).frame(width: 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(h.selectedText)
                                .font(.system(size: 13, design: .serif))
                            Text(L("notes.page_format", h.page + 1))
                                .font(.mUICaption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func metaRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.mUICaption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.mUICaption.monospacedDigit())
        }
    }

    private func toggle(category: Category) {
        if let idx = book.categoryIDs.firstIndex(of: category.id) {
            book.categoryIDs.remove(at: idx)
        } else {
            book.categoryIDs.append(category.id)
        }
        store.touch()
    }
}

private struct EmptyTab: View {
    let message: String
    var body: some View {
        VStack(spacing: Tokens.Spacing.m) {
            Image(systemName: "doc.text")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.mUIBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Tokens.Spacing.xxl)
    }
}
