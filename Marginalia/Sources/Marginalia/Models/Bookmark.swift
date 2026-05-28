import Foundation
import Observation

@Observable
final class Bookmark: Identifiable, Codable {
    let id: UUID
    let bookID: UUID
    var page: Int
    var createdAt: Date

    init(id: UUID = UUID(), bookID: UUID, page: Int, createdAt: Date = .now) {
        self.id = id
        self.bookID = bookID
        self.page = page
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id, bookID, page, createdAt
    }

    convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            bookID: try c.decode(UUID.self, forKey: .bookID),
            page: try c.decode(Int.self, forKey: .page),
            createdAt: try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(bookID, forKey: .bookID)
        try c.encode(page, forKey: .page)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

extension Bookmark: Hashable {
    static func == (lhs: Bookmark, rhs: Bookmark) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
