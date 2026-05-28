import SwiftUI

struct ReaderHost: View {
    let bookID: UUID
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        if let book = store.book(id: bookID) {
            ReaderView(book: book, dismiss: { dismissWindow(id: "reader", value: bookID) })
        } else {
            VStack(spacing: Tokens.Spacing.m) {
                Text(L("reader.book_not_found"))
                Button(L("common.go_back")) { dismissWindow(id: "reader", value: bookID) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
