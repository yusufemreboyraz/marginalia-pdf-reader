import SwiftUI

/// Adaptive grid with "vary spacing" — currently-reading books render slightly larger; finished books a bit smaller.
struct CoverGrid: View {
    let books: [Book]

    private let columns = [GridItem(.adaptive(minimum: 120, maximum: 180), spacing: 28, alignment: .top)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 36) {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    CoverTile(book: book)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CoverTile: View {
    let book: Book
    @State private var hovering = false

    var scale: CGFloat {
        switch book.status {
        case .reading:  return 1.05
        case .finished: return 0.92
        default:        return 1.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.s) {
            ZStack(alignment: .leading) {
                CoverImage(book: book)
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.m))
                    .shadow(color: .black.opacity(hovering ? 0.18 : 0.10), radius: hovering ? 8 : 4, x: 0, y: hovering ? 4 : 2)

                if book.status == .reading {
                    // Ribbon — functional brand-hue accent, not a decorative side stripe.
                    Rectangle()
                        .fill(Tokens.Brand.ribbon)
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5))
                        .padding(.vertical, 4)
                }
            }
            .scaleEffect(scale * (hovering ? 1.02 : 1.0))
            .animation(.smooth(duration: 0.18), value: hovering)

            Text(book.title)
                .font(.mUIBody)
                .lineLimit(1)
                .foregroundStyle(.primary)

            if hovering {
                Text(book.author.isEmpty ? "—" : book.author)
                    .font(.mUICaption)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .onHover { hovering = $0 }
        .help(book.author.isEmpty ? book.title : "\(book.title) — \(book.author)")
    }
}

struct CoverImage: View {
    let book: Book

    var body: some View {
        Group {
            if let data = book.coverData, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Tokens.Paper.surface, Tokens.Paper.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 4) {
                Image(systemName: "book.closed")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Tokens.Brand.ribbon.opacity(0.7))
                Text(book.title.prefix(24))
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(Tokens.Paper.ink.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineLimit(3)
            }
        }
    }
}
