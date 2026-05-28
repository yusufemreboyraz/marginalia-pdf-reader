import Foundation
import Observation

@Observable
final class Highlight: Identifiable, Codable {
    let id: UUID
    let bookID: UUID
    var page: Int
    var selectedText: String
    /// Optional reader note attached to this highlight.
    var note: String
    var createdAt: Date
    /// Serialized selection bounds for re-rendering on the PDF.
    var bounds: Data?

    init(
        id: UUID = UUID(),
        bookID: UUID,
        page: Int,
        selectedText: String,
        note: String = "",
        createdAt: Date = .now,
        bounds: Data? = nil
    ) {
        self.id = id
        self.bookID = bookID
        self.page = page
        self.selectedText = selectedText
        self.note = note
        self.createdAt = createdAt
        self.bounds = bounds
    }

    var hasNote: Bool { !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    enum CodingKeys: String, CodingKey {
        case id, bookID, page, selectedText, note, createdAt, bounds
    }

    convenience init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try c.decode(UUID.self, forKey: .id),
            bookID: try c.decode(UUID.self, forKey: .bookID),
            page: try c.decode(Int.self, forKey: .page),
            selectedText: try c.decode(String.self, forKey: .selectedText),
            note: try c.decodeIfPresent(String.self, forKey: .note) ?? "",
            createdAt: try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now,
            bounds: try c.decodeIfPresent(Data.self, forKey: .bounds)
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(bookID, forKey: .bookID)
        try c.encode(page, forKey: .page)
        try c.encode(selectedText, forKey: .selectedText)
        try c.encode(note, forKey: .note)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(bounds, forKey: .bounds)
    }
}

extension Highlight: Hashable {
    static func == (lhs: Highlight, rhs: Highlight) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
