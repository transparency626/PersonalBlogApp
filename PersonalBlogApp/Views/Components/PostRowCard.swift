import SwiftUI

struct PostRowCard: View {
    let post: BlogPost

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: post.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 110)
                .overlay(alignment: .bottomLeading) {
                    Text(post.category)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                }

            VStack(alignment: .leading, spacing: 10) {
                Text(post.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(post.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label(post.publishLabel, systemImage: "calendar")
                    Label("\(post.readingTime) min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 18, x: 0, y: 10)
    }
}
