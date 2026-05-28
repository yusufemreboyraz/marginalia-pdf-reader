import Foundation

/// On-disk locations for the managed book library and the SwiftData store.
enum LibraryStorage {
    static let appSupportDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Marginalia", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let booksDirectory: URL = {
        let dir = appSupportDirectory.appendingPathComponent("Books", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let storeURL: URL = appSupportDirectory.appendingPathComponent("marginalia.store")
}
