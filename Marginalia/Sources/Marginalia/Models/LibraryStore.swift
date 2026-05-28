import Foundation
import Observation
import AppKit

/// In-memory store for the entire library. Owns all models and persists them
/// to a JSON file under Application Support/Marginalia/library.json. Saves are
/// debounced so rapid mutations (page advances, note typing) coalesce.
@Observable
@MainActor
final class LibraryStore {
    private(set) var books: [Book]
    private(set) var highlights: [Highlight]
    private(set) var bookmarks: [Bookmark]
    private(set) var categories: [Category]

    private var saveTask: Task<Void, Never>?

    init() {
        let snapshot = LibraryStore.loadFromDisk()
        self.books = snapshot.books
        self.highlights = snapshot.highlights
        self.bookmarks = snapshot.bookmarks
        self.categories = snapshot.categories
    }

    // MARK: - Mutations

    func addBook(_ book: Book) {
        books.append(book)
        scheduleSave()
    }

    func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        highlights.removeAll { $0.bookID == book.id }
        bookmarks.removeAll { $0.bookID == book.id }
        try? FileManager.default.removeItem(at: book.fileURL)
        scheduleSave()
    }

    func addHighlight(_ h: Highlight) {
        highlights.append(h)
        scheduleSave()
    }

    func deleteHighlight(_ h: Highlight) {
        highlights.removeAll { $0.id == h.id }
        scheduleSave()
    }

    func addBookmark(_ bm: Bookmark) {
        bookmarks.append(bm)
        scheduleSave()
    }

    func deleteBookmark(_ bm: Bookmark) {
        bookmarks.removeAll { $0.id == bm.id }
        scheduleSave()
    }

    func addCategory(_ c: Category) {
        categories.append(c)
        scheduleSave()
    }

    func deleteCategory(_ c: Category) {
        categories.removeAll { $0.id == c.id }
        for book in books {
            book.categoryIDs.removeAll { $0 == c.id }
        }
        scheduleSave()
    }

    /// Call after mutating an existing model's properties so the change is persisted.
    func touch() {
        scheduleSave()
    }

    // MARK: - Queries

    func book(id: UUID) -> Book? { books.first { $0.id == id } }

    func highlights(for book: Book) -> [Highlight] {
        highlights.filter { $0.bookID == book.id }
    }

    func bookmarks(for book: Book) -> [Bookmark] {
        bookmarks.filter { $0.bookID == book.id }
    }

    func categories(for book: Book) -> [Category] {
        let ids = Set(book.categoryIDs)
        return categories.filter { ids.contains($0.id) }
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var books: [Book] = []
        var highlights: [Highlight] = []
        var bookmarks: [Bookmark] = []
        var categories: [Category] = []
    }

    private static func loadFromDisk() -> Snapshot {
        let url = LibraryStorage.storeURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return Snapshot()
        }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Snapshot.self, from: data)
        } catch {
            // If decoding fails, keep the broken file aside so we don't lose user data.
            let backup = url.deletingPathExtension().appendingPathExtension("broken.\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: url, to: backup)
            return Snapshot()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self.persist()
        }
    }

    private func persist() async {
        let snapshot = Snapshot(
            books: books,
            highlights: highlights,
            bookmarks: bookmarks,
            categories: categories
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: LibraryStorage.storeURL, options: .atomic)
        } catch {
            NSLog("Marginalia: failed to persist library — \(error)")
        }
    }
}
