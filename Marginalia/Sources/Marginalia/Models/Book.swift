import Foundation
import Observation

@Observable
final class Book: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    /// File name inside the managed library directory.
    var fileName: String
    var addedAt: Date
    var lastOpenedAt: Date?
    var pageCount: Int
    var currentPage: Int
    var rating: Int
    var status: ReadingStatus
    /// Encoded cover JPEG (base64 on disk; raw Data in memory).
    var coverData: Data?
    /// IDs of categories this book belongs to.
    var categoryIDs: [UUID]

    init(
        id: UUID = UUID(),
        title: String,
        author: String = "",
        fileName: String,
        addedAt: Date = .now,
        lastOpenedAt: Date? = nil,
        pageCount: Int = 0,
        currentPage: Int = 0,
        rating: Int = 0,
        status: ReadingStatus = .unread,
        coverData: Data? = nil,
        categoryIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.fileName = fileName
        self.addedAt = addedAt
        self.lastOpenedAt = lastOpenedAt
        self.pageCount = pageCount
        self.currentPage = currentPage
        self.rating = rating
        self.status = status
        self.coverData = coverData
        self.categoryIDs = categoryIDs
    }

    var fileURL: URL {
        LibraryStorage.booksDirectory.appendingPathComponent(fileName)
    }

    var progress: Double {
        guard pageCount > 0 else { return 0 }
        return min(1, Double(currentPage) / Double(pageCount))
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, title, author, fileName, addedAt, lastOpenedAt
        case pageCount, currentPage, rating, status, coverData, categoryIDs
    }

    convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            title: try c.decode(String.self, forKey: .title),
            author: try c.decodeIfPresent(String.self, forKey: .author) ?? "",
            fileName: try c.decode(String.self, forKey: .fileName),
            addedAt: try c.decodeIfPresent(Date.self, forKey: .addedAt) ?? .now,
            lastOpenedAt: try c.decodeIfPresent(Date.self, forKey: .lastOpenedAt),
            pageCount: try c.decodeIfPresent(Int.self, forKey: .pageCount) ?? 0,
            currentPage: try c.decodeIfPresent(Int.self, forKey: .currentPage) ?? 0,
            rating: try c.decodeIfPresent(Int.self, forKey: .rating) ?? 0,
            status: try c.decodeIfPresent(ReadingStatus.self, forKey: .status) ?? .unread,
            coverData: try c.decodeIfPresent(Data.self, forKey: .coverData),
            categoryIDs: try c.decodeIfPresent([UUID].self, forKey: .categoryIDs) ?? []
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(author, forKey: .author)
        try c.encode(fileName, forKey: .fileName)
        try c.encode(addedAt, forKey: .addedAt)
        try c.encodeIfPresent(lastOpenedAt, forKey: .lastOpenedAt)
        try c.encode(pageCount, forKey: .pageCount)
        try c.encode(currentPage, forKey: .currentPage)
        try c.encode(rating, forKey: .rating)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(coverData, forKey: .coverData)
        try c.encode(categoryIDs, forKey: .categoryIDs)
    }
}

extension Book: Hashable {
    static func == (lhs: Book, rhs: Book) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
