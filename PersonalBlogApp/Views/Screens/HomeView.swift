import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: BlogViewModel

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        introSection

                        if let featuredPost = viewModel.featuredPost {
                            NavigationLink {
                                ArticleDetailView(post: featuredPost)
                            } label: {
                                FeaturedPostCard(post: featuredPost)
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "What I Write",
                                subtitle: "把学习记录、产品思考和项目拆解整理成可展示的博客内容。"
                            )

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.categories, id: \.self) { category in
                                        TagChip(text: category)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(
                                title: "Latest Posts",
                                subtitle: "最新更新的文章会在这里展示。"
                            )

                            ForEach(viewModel.latestPosts.prefix(3)) { post in
                                NavigationLink {
                                    ArticleDetailView(post: post)
                                } label: {
                                    PostRowCard(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Personal Blog")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build in public, grow in public.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("一个面向求职展示的 SwiftUI 个人博客 Demo，用来呈现我的项目能力、设计感觉和 iOS 成长轨迹。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Label("SwiftUI", systemImage: "swift")
                Label("Portfolio", systemImage: "rectangle.stack.person.crop")
                Label("iOS Career", systemImage: "briefcase")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
