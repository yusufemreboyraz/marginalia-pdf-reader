import Foundation

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case unread
    case reading
    case finished
    case wishlist

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unread:   return L("status.unread")
        case .reading:  return L("status.reading")
        case .finished: return L("status.finished")
        case .wishlist: return L("status.wishlist")
        }
    }

    var systemImage: String {
        switch self {
        case .unread:   return "book.closed"
        case .reading:  return "book"
        case .finished: return "checkmark.seal"
        case .wishlist: return "bookmark"
        }
    }
}
