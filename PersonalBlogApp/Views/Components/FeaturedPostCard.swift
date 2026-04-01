import SwiftUI

struct FeaturedPostCard: View {
    let post: BlogPost

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())

                Spacer()

                Label("\(post.readingTime) min", systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(post.category.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.88))

                Text(post.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(post.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(3)
            }

            HStack(spacing: 10) {
                ForEach(post.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 250, alignment: .bottomLeading)
        .background(
            LinearGradient(
                colors: post.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: post.gradientColors.last?.opacity(0.28) ?? .black.opacity(0.16), radius: 24, x: 0, y: 16)
    }
}
