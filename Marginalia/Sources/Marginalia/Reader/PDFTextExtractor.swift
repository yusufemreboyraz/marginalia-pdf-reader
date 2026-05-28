import Foundation
import PDFKit

/// One PDF page's plain text content. Page numbers preserved so we can still
/// jump to "page N" from bookmarks / highlights even in reflow mode.
struct ExtractedPage: Identifiable, Hashable {
    let id: Int
    var pageIndex: Int { id }
    let text: String

    /// Heuristic: true if this page is effectively empty (whitespace / page
    /// number only). Used to skip blank fillers in the reflow stream.
    var isEffectivelyEmpty: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        // Page number on its own line (1–4 digits).
        if trimmed.count <= 4, Int(trimmed) != nil { return true }
        return false
    }
}

enum PDFTextExtractor {
    /// Walk every page and pull its `string`. PDFKit returns nil for
    /// scanned/image-only pages, which we render as a placeholder hint.
    static func extract(from document: PDFDocument) -> [ExtractedPage] {
        (0..<document.pageCount).map { i in
            let raw = document.page(at: i)?.string ?? ""
            return ExtractedPage(id: i, text: clean(raw))
        }
    }

    /// PDF.string returns text with line breaks at every visual line. That
    /// shreds paragraphs into 4–5 word fragments when reflowed. Heuristic
    /// re-flow: join lines that don't end at sentence boundaries, keep blank
    /// lines as paragraph breaks.
    private static func clean(_ raw: String) -> String {
        // Normalize line endings.
        let normalized = raw.replacingOccurrences(of: "\r\n", with: "\n")
                            .replacingOccurrences(of: "\r", with: "\n")

        let rawLines = normalized.components(separatedBy: "\n")
        var paragraphs: [String] = []
        var current: [String] = []

        func flush() {
            if !current.isEmpty {
                paragraphs.append(current.joined(separator: " "))
                current.removeAll()
            }
        }

        for raw in rawLines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flush()
            } else {
                current.append(line)
            }
        }
        flush()

        // Collapse double spaces that slipped in from the joins.
        let collapsed = paragraphs.map { paragraph in
            paragraph.replacingOccurrences(of: "  ", with: " ")
        }
        return collapsed.joined(separator: "\n\n")
    }
}
