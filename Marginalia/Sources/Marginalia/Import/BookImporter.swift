import Foundation
import PDFKit
import AppKit

enum ImportError: LocalizedError {
    case notAPDF
    case copyFailed(Error)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .notAPDF:           return L("error.not_pdf")
        case .unreadable:        return L("error.unreadable")
        case .copyFailed(let e): return L("error.copy_failed_format", e.localizedDescription)
        }
    }
}

enum BookImporter {
    @MainActor
    static func `import`(from sourceURL: URL, into store: LibraryStore) throws {
        let didStart = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStart { sourceURL.stopAccessingSecurityScopedResource() } }

        guard sourceURL.pathExtension.lowercased() == "pdf" else {
            throw ImportError.notAPDF
        }
        guard let document = PDFDocument(url: sourceURL) else {
            throw ImportError.unreadable
        }

        let targetName = uniqueFileName(for: sourceURL.lastPathComponent)
        let targetURL = LibraryStorage.booksDirectory.appendingPathComponent(targetName)
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
        } catch {
            throw ImportError.copyFailed(error)
        }

        let (title, author) = metadata(from: document, fallbackName: sourceURL.deletingPathExtension().lastPathComponent)
        let cover = renderCover(from: document)

        let book = Book(
            title: title,
            author: author,
            fileName: targetName,
            pageCount: document.pageCount,
            coverData: cover
        )
        store.addBook(book)
    }

    private static func uniqueFileName(for original: String) -> String {
        let base = (original as NSString).deletingPathExtension
        let ext = (original as NSString).pathExtension
        var candidate = original
        var i = 1
        while FileManager.default.fileExists(atPath: LibraryStorage.booksDirectory.appendingPathComponent(candidate).path) {
            candidate = "\(base) (\(i)).\(ext)"
            i += 1
        }
        return candidate
    }

    private static func metadata(from doc: PDFDocument, fallbackName: String) -> (title: String, author: String) {
        let attrs = doc.documentAttributes ?? [:]
        let title = (attrs[PDFDocumentAttribute.titleAttribute] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let author = (attrs[PDFDocumentAttribute.authorAttribute] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = (title?.isEmpty == false ? title : nil) ?? fallbackName
        return (finalTitle, author ?? "")
    }

    private static func renderCover(from doc: PDFDocument) -> Data? {
        guard let page = doc.page(at: 0) else { return nil }
        let pageRect = page.bounds(for: .mediaBox)
        let targetSize = CGSize(width: 400, height: 400 * (pageRect.height / pageRect.width))
        let image = NSImage(size: targetSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: targetSize)).fill()

        guard let ctx = NSGraphicsContext.current?.cgContext else { return nil }
        ctx.saveGState()
        let scale = targetSize.width / pageRect.width
        ctx.translateBy(x: 0, y: targetSize.height)
        ctx.scaleBy(x: scale, y: -scale)
        page.draw(with: .mediaBox, to: ctx)
        ctx.restoreGState()

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.78]) else {
            return nil
        }
        return data
    }
}
