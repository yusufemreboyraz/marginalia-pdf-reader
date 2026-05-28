import Foundation

enum LibraryScope: Hashable {
    case all
    case status(ReadingStatus)
    case category(UUID)

    var title: String {
        switch self {
        case .all: return L("scope.all")
        case .status(let s): return s.label
        case .category: return L("scope.category")
        }
    }
}
