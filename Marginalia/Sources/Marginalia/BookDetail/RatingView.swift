import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    var max: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...max, id: \.self) { i in
                Button {
                    rating = (rating == i) ? 0 : i
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundStyle(i <= rating ? Tokens.Brand.ribbon : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help(L("rating.stars_format", i))
            }
        }
    }
}
