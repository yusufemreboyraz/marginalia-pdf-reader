import SwiftUI

struct RootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.openWindow) private var openWindow
    @State private var selection: LibraryScope = .all
    @State private var path = NavigationPath()
    @State private var searchText: String = ""

    var body: some View {
        NavigationSplitView {
            LibrarySidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            NavigationStack(path: $path) {
                LibraryView(scope: selection, searchText: $searchText)
                    .navigationDestination(for: Book.self) { book in
                        BookDetailView(book: book) {
                            openWindow(id: "reader", value: book.id)
                        }
                    }
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: Text(L("library.search_placeholder")))
        }
    }
}
