import SwiftUI
import PDFKit
import AppKit

/// Lightweight bridge so SwiftUI can drive PDFView's built-in page navigation,
/// which is mode-aware (one page at a time in `.singlePage`, two at a time in
/// `.twoUp`). Driving currentPage manually would break the spread.
@MainActor
final class PDFController {
    weak var view: PDFView?

    func next() { view?.goToNextPage(nil) }
    func previous() { view?.goToPreviousPage(nil) }
    func go(to pageIndex: Int) {
        guard let view, let doc = view.document, let page = doc.page(at: max(0, min(pageIndex, doc.pageCount - 1))) else { return }
        view.go(to: page)
    }
}

/// SwiftUI wrapper over PDFKit's PDFView. Color theming is **not** done here —
/// SwiftUI modifiers on the outside (`.colorMultiply`, `.colorInvert`,
/// `.blendMode(.screen)`) recolor the rendered output, because PDFKit draws
/// into private sub-layers that `CALayer.filters` does not reach.
struct PDFViewRepresentable: NSViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    let highlights: [Highlight]
    let onSelectionChange: (PDFSelection?) -> Void
    let twoUp: Bool
    let controller: PDFController

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = twoUp ? .twoUp : .singlePage
        view.displayDirection = .horizontal
        view.displaysAsBook = true
        // Transparent everywhere PDFView would draw chrome — surface lives
        // behind in SwiftUI, so every pixel that isn't ink is the theme color.
        view.backgroundColor = .clear
        // **Critical for Apple Books look**: disable the page frame PDFKit
        // draws around each page (the rectangle that made pages look like
        // tiles on a tray), and zero out the gutter so there's no extra
        // separation tone between pages.
        view.displaysPageBreaks = false
        view.pageBreakMargins = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.delegate = context.coordinator

        controller.view = view

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionChanged(_:)),
            name: .PDFViewSelectionChanged,
            object: view
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: view
        )

        if let target = document.page(at: max(0, currentPage)) {
            DispatchQueue.main.async { view.go(to: target) }
        }
        applyHighlights(to: view)
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        view.backgroundColor = .clear
        let desiredMode: PDFDisplayMode = twoUp ? .twoUp : .singlePage
        if view.displayMode != desiredMode {
            view.displayMode = desiredMode
        }
        controller.view = view

        if let docPage = view.currentPage,
           let idx = view.document?.index(for: docPage),
           idx != currentPage,
           let target = view.document?.page(at: max(0, min(currentPage, (view.document?.pageCount ?? 1) - 1))) {
            view.go(to: target)
        }

        applyHighlights(to: view)
    }

    private func applyHighlights(to view: PDFView) {
        guard let doc = view.document else { return }
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            for ann in page.annotations where ann.contents == "Marginalia" {
                page.removeAnnotation(ann)
            }
        }
        for h in highlights {
            guard let page = doc.page(at: h.page) else { continue }
            guard let data = h.bounds,
                  let stored = try? JSONDecoder().decode([CGRectStorage].self, from: data) else { continue }
            for rect in stored {
                let ann = PDFAnnotation(bounds: rect.cgRect, forType: .highlight, withProperties: nil)
                ann.color = NSColor(Tokens.Brand.ribbon).withAlphaComponent(0.35)
                ann.contents = "Marginalia"
                page.addAnnotation(ann)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage, onSelectionChange: onSelectionChange)
    }

    @MainActor
    final class Coordinator: NSObject, PDFViewDelegate {
        let currentPage: Binding<Int>
        let onSelectionChange: (PDFSelection?) -> Void

        init(currentPage: Binding<Int>, onSelectionChange: @escaping (PDFSelection?) -> Void) {
            self.currentPage = currentPage
            self.onSelectionChange = onSelectionChange
        }

        @objc func selectionChanged(_ note: Notification) {
            guard let view = note.object as? PDFView else { return }
            onSelectionChange(view.currentSelection)
        }

        @objc func pageChanged(_ note: Notification) {
            guard let view = note.object as? PDFView,
                  let page = view.currentPage,
                  let idx = view.document?.index(for: page) else { return }
            if currentPage.wrappedValue != idx {
                currentPage.wrappedValue = idx
            }
        }
    }
}

struct CGRectStorage: Codable, Sendable {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat

    init(_ r: CGRect) {
        self.x = r.minX
        self.y = r.minY
        self.w = r.width
        self.h = r.height
    }

    var cgRect: CGRect { CGRect(x: x, y: y, width: w, height: h) }
}

enum PDFSelectionEncoder {
    static func encode(_ selection: PDFSelection, in document: PDFDocument) -> (page: Int, data: Data, text: String)? {
        guard let firstPage = selection.pages.first else { return nil }
        let pageIndex = document.index(for: firstPage)
        let rects = selection.selectionsByLine().compactMap { line -> CGRectStorage? in
            guard let page = line.pages.first else { return nil }
            return CGRectStorage(line.bounds(for: page))
        }
        guard !rects.isEmpty, let data = try? JSONEncoder().encode(rects) else { return nil }
        return (pageIndex, data, selection.string ?? "")
    }
}
