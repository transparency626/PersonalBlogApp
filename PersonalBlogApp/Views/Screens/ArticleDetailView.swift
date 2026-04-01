import SwiftUI

struct ArticleDetailView: View {
    let post: BlogPost

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroSection

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(post.sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.title3.bold())

                            Text(section.body)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineSpacing(6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.white, Color(red: 0.96, green: 0.97, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: post.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 260)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.category.uppercased())
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.9))

                        Text(post.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(post.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(24)
                }

            HStack(spacing: 16) {
                Label(post.publishLabel, systemImage: "calendar")
                Label("\(post.readingTime) min read", systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(post.tags, id: \.self) { tag in
                        TagChip(text: tag)
                    }
                }
            }

            Text(post.excerpt)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
        }
        .padding(20)
    }
}
