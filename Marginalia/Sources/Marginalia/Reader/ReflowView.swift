import SwiftUI

/// True Apple Books-style reader: PDF text extracted into pure SwiftUI Text
/// views with our own typography on the themed surface. No page rectangles,
/// no PDFKit shadows, no fixed layout — just ink on the chosen surface.
struct ReflowView: View {
    let pages: [ExtractedPage]
    let bookTitle: String
    let themeMode: ThemeMode
    @Binding var currentPage: Int

    @AppStorage("reflowFontSize") private var fontSize: Double = 18
    @AppStorage("reflowFontDesignRaw") private var fontDesignRaw: String = FontDesign.serif.rawValue
    @AppStorage("reflowLineSpacing") private var lineSpacing: Double = 8

    enum FontDesign: String, CaseIterable, Identifiable {
        case serif, sans, mono
        var id: String { rawValue }
        var label: String {
            switch self {
            case .serif: return L("reflow.font.serif")
            case .sans:  return L("reflow.font.sans")
            case .mono:  return L("reflow.font.mono")
            }
        }
        var design: Font.Design {
            switch self {
            case .serif: return .serif
            case .sans:  return .default
            case .mono:  return .monospaced
            }
        }
    }

    private var fontDesign: Font.Design {
        FontDesign(rawValue: fontDesignRaw)?.design ?? .serif
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(pages) { page in
                        pageBlock(page)
                            .id(page.pageIndex)
                    }
                }
                .frame(maxWidth: 720)                            // newspaper-column width
                .padding(.horizontal, 80)
                .padding(.vertical, 80)
                .frame(maxWidth: .infinity)                      // center the column
            }
            .background(themeMode.surface.ignoresSafeArea())
            .onAppear {
                // Snap to the page the user left off on.
                if currentPage > 0 {
                    proxy.scrollTo(currentPage, anchor: .top)
                }
            }
            .onChange(of: currentPage) { _, newValue in
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(newValue, anchor: .top)
                }
            }
        }
        .overlay(alignment: .topTrailing) { fontControls }
    }

    @ViewBuilder
    private func pageBlock(_ page: ExtractedPage) -> some View {
        if page.isEffectivelyEmpty {
            // Keep the slot so page numbers still align, but render nothing visible.
            Color.clear.frame(height: 1)
        } else {
            VStack(alignment: .leading, spacing: lineSpacing * 2) {
                // Paragraphs separated by blank lines in the extractor output.
                ForEach(Array(page.text.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                    let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        Text(trimmed)
                            .font(.system(size: fontSize, design: fontDesign))
                            .foregroundColor(themeMode.readingInk)
                            .lineSpacing(lineSpacing)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                Text(L("reflow.page_marker_format", page.pageIndex + 1))
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(themeMode.readingInkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, lineSpacing * 4)
                    .padding(.bottom, lineSpacing * 6)
            }
        }
    }

    private var fontControls: some View {
        HStack(spacing: Tokens.Spacing.s) {
            Button {
                fontSize = max(13, fontSize - 1)
            } label: {
                Image(systemName: "textformat.size.smaller")
            }
            .buttonStyle(.borderless)

            Text("\(Int(fontSize))")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(themeMode.readingInkSecondary)
                .frame(minWidth: 18)

            Button {
                fontSize = min(28, fontSize + 1)
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .buttonStyle(.borderless)

            Divider().frame(height: 14)

            Menu {
                ForEach(FontDesign.allCases) { design in
                    Button {
                        fontDesignRaw = design.rawValue
                    } label: {
                        HStack {
                            Text(design.label)
                            if design.rawValue == fontDesignRaw {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "textformat")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .foregroundStyle(themeMode.readingInk)
        .padding(.horizontal, Tokens.Spacing.m)
        .padding(.vertical, Tokens.Spacing.s)
        .background(themeMode.surface.opacity(0.85), in: Capsule())
        .overlay(Capsule().stroke(themeMode.readingInkSecondary.opacity(0.2), lineWidth: 0.5))
        .padding(Tokens.Spacing.l)
    }
}
