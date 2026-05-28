import SwiftUI

struct NotesPanel: View {
    @Bindable var book: Book
    let jumpToPage: (Int) -> Void
    @Environment(LibraryStore.self) private var store

    private var sortedHighlights: [Highlight] {
        store.highlights(for: book).sorted { $0.createdAt < $1.createdAt }
    }

    private var sortedBookmarks: [Bookmark] {
        store.bookmarks(for: book).sorted { $0.page < $1.page }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if sortedHighlights.isEmpty && sortedBookmarks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.l) {
                        if !sortedBookmarks.isEmpty {
                            section(L("notes.bookmarks")) {
                                ForEach(sortedBookmarks) { bm in
                                    bookmarkRow(bm)
                                }
                            }
                        }
                        if !sortedHighlights.isEmpty {
                            section(L("notes.highlights")) {
                                ForEach(sortedHighlights) { h in
                                    highlightRow(h)
                                }
                            }
                        }
                    }
                    .padding(Tokens.Spacing.l)
                }
            }
        }
        .background(.regularMaterial)
        .overlay(alignment: .leading) {
            Rectangle().fill(.separator).frame(width: 0.5)
        }
    }

    private var header: some View {
        HStack {
            Text(L("notes.title")).font(.mUITitle)
            Spacer()
            Text("\(sortedHighlights.count + sortedBookmarks.count)")
                .font(.mUICaption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Tokens.Spacing.l)
        .padding(.vertical, Tokens.Spacing.m)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            content()
        }
    }

    private func bookmarkRow(_ bm: Bookmark) -> some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(Tokens.Brand.ribbon)
            Text(L("notes.page_format", bm.page + 1))
                .font(.mUIBody)
            Spacer()
            Button {
                store.deleteBookmark(bm)
            } label: {
                Image(systemName: "xmark").foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .opacity(0.6)
        }
        .padding(Tokens.Spacing.s)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: Tokens.Radius.s))
        .contentShape(Rectangle())
        .onTapGesture { jumpToPage(bm.page) }
    }

    private func highlightRow(_ h: Highlight) -> some View {
        @Bindable var highlight = h
        return VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            HStack(alignment: .top, spacing: Tokens.Spacing.s) {
                Rectangle()
                    .fill(Tokens.Brand.ribbon)
                    .frame(width: 2)
                Text(h.selectedText.isEmpty ? "—" : h.selectedText)
                    .font(.system(size: 13, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField(L("notes.placeholder"), text: $highlight.note, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.mUIBody)
                .lineLimit(1...4)
                .onChange(of: h.note) { _, _ in store.touch() }

            HStack {
                Button {
                    jumpToPage(h.page)
                } label: {
                    Text(L("notes.page_format", h.page + 1)).font(.mUICaption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button {
                    store.deleteHighlight(h)
                } label: {
                    Image(systemName: "trash").font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(Tokens.Spacing.m)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: Tokens.Radius.m))
    }

    private var emptyState: some View {
        VStack(spacing: Tokens.Spacing.m) {
            Image(systemName: "note.text")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(.tertiary)
            Text(L("notes.empty.title")).font(.mUIBody).foregroundStyle(.secondary)
            Text(L("notes.empty.body"))
                .font(.mUICaption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
