import SwiftUI

struct LibrarySidebar: View {
    @Binding var selection: LibraryScope
    @Environment(LibraryStore.self) private var store
    @State private var newCategoryName: String = ""
    @State private var addingCategory: Bool = false

    var body: some View {
        List(selection: $selection) {
            Section {
                row(label: "Tümü",                       image: "books.vertical",                  scope: .all)
                row(label: ReadingStatus.reading.label,  image: ReadingStatus.reading.systemImage, scope: .status(.reading))
                row(label: ReadingStatus.finished.label, image: ReadingStatus.finished.systemImage, scope: .status(.finished))
                row(label: ReadingStatus.unread.label,   image: ReadingStatus.unread.systemImage,  scope: .status(.unread))
                row(label: ReadingStatus.wishlist.label, image: ReadingStatus.wishlist.systemImage, scope: .status(.wishlist))
            }

            Section(L("sidebar.categories")) {
                ForEach(store.categories.sorted { $0.createdAt < $1.createdAt }) { cat in
                    row(label: cat.name, image: "tag", scope: .category(cat.id))
                        .contextMenu {
                            Button(L("sidebar.delete"), role: .destructive) {
                                store.deleteCategory(cat)
                            }
                        }
                }

                if addingCategory {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundStyle(.tertiary)
                        TextField(L("sidebar.category_name"), text: $newCategoryName)
                            .textFieldStyle(.plain)
                            .onSubmit(commitCategory)
                        Button(action: commitCategory) {
                            Image(systemName: "return")
                        }
                        .buttonStyle(.plain)
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } else {
                    Button {
                        addingCategory = true
                    } label: {
                        Label(L("sidebar.add_category"), systemImage: "plus")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func row(label: String, image: String, scope: LibraryScope) -> some View {
        Label(label, systemImage: image).tag(scope)
    }

    private func commitCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addCategory(Category(name: trimmed))
        newCategoryName = ""
        addingCategory = false
    }
}
