import SwiftUI

struct AboutView: View {
    @ObservedObject var viewModel: BlogViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var author: AuthorProfile {
        viewModel.author
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        profileSection

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.profileStats) { stat in
                                ProfileStatCard(stat: stat)
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(
                                title: "Career Goals",
                                subtitle: "我希望通过持续做项目，把学习成果变成可验证的能力。"
                            )

                            ForEach(author.goals, id: \.self) { goal in
                                Label(goal, systemImage: "checkmark.seal.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(
                                title: "Skills",
                                subtitle: "当前重点积累的方向。"
                            )

                            FlexibleTagWrap(tags: author.skills)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("About Me")
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(author.name)
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text(author.role)
                .font(.headline)
                .foregroundStyle(Color.accentColor)

            Text(author.bio)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)

            HStack(spacing: 16) {
                Label(author.education, systemImage: "graduationcap")
                Label(author.location, systemImage: "mappin.and.ellipse")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

private struct FlexibleTagWrap: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(tagRows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { tag in
                        TagChip(text: tag)
                    }
                }
            }
        }
    }

    private var tagRows: [[String]] {
        stride(from: 0, to: tags.count, by: 3).map { index in
            Array(tags[index..<min(index + 3, tags.count)])
        }
    }
}
