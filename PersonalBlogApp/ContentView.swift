import SwiftUI

struct ContentView: View {
    @State private var posts: [BlogPost] = []
    @State private var isComposerPresented = false
    @State private var postPendingDeletion: BlogPost?

    @State private var draftTitle = ""
    @State private var draftSubtitle = ""
    @State private var draftCategory = ""
    @State private var draftTagsText = ""
    @State private var draftContent = ""
    @State private var draftIsFeatured = false
    @State private var draftTheme: BlogTheme = .blue

    private let author = AuthorProfile(
        name: "Chen",
        role: "Aspiring iOS Developer",
        bio: "本科在读，主攻 SwiftUI、产品体验和移动端交互设计。我希望把学习过程、项目拆解和开发思考沉淀成高质量内容。",
        location: "China",
        education: "Computer Science Undergraduate",
        goals: [
            "找到一份 iOS 开发实习或校招岗位",
            "持续打磨 SwiftUI 和网络层能力",
            "做出更完整的移动端作品"
        ],
        skills: ["Swift", "SwiftUI", "REST API", "Git/GitHub", "UI/UX Thinking"]
    )

    var body: some View {
        TabView {
            HomeTab(posts: posts)
                .tabItem { Label("Home", systemImage: "house.fill") }

            ArticlesTab(
                posts: posts,
                isComposerPresented: $isComposerPresented,
                postPendingDeletion: $postPendingDeletion
            )
            .tabItem { Label("Articles", systemImage: "newspaper.fill") }

            AboutTab(author: author, postCount: posts.count)
                .tabItem { Label("About", systemImage: "person.fill") }
        }
        .tint(Color.accentColor)
        .sheet(isPresented: $isComposerPresented) {
            composerSheet
        }
        .alert("删除这篇文章？", isPresented: Binding(get: {
            postPendingDeletion != nil
        }, set: { visible in
            if !visible { postPendingDeletion = nil }
        })) {
            Button("取消", role: .cancel) {
                postPendingDeletion = nil
            }
            Button("删除", role: .destructive) {
                if let target = postPendingDeletion {
                    posts.removeAll { $0.id == target.id }
                }
                postPendingDeletion = nil
            }
        } message: {
            Text("删除后会同步从本地存储移除。")
        }
        .task {
            let fileURL = storageURL()
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([BlogPost].self, from: data),
               !decoded.isEmpty {
                posts = decoded
            } else {
                posts = demoPosts()
            }
        }
        .onChange(of: posts) { _, value in
            let fileURL = storageURL()
            if let data = try? JSONEncoder().encode(value) {
                try? data.write(to: fileURL, options: [.atomic])
            }
        }
    }

    private var composerSheet: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $draftTitle)
                    TextField("副标题", text: $draftSubtitle, axis: .vertical)
                    TextField("分类，例如 SwiftUI / Interview", text: $draftCategory)
                    TextField("标签（直接文本）", text: $draftTagsText)
                }

                Section("正文") {
                    TextEditor(text: $draftContent)
                        .frame(minHeight: 220)
                }

                Section("展示样式") {
                    Picker("主题", selection: $draftTheme) {
                        ForEach(BlogTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    Toggle("设为首页 Featured 文章", isOn: $draftIsFeatured)

                    HStack {
                        Label("预计阅读时长", systemImage: "clock")
                        Spacer()
                        Text("\(max(1, draftContent.count / 180)) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        isComposerPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("发布") {
                        var next = posts
                        if draftIsFeatured {
                            for i in next.indices {
                                next[i].isFeatured = false
                            }
                        }

                        next.insert(
                            BlogPost(
                                title: draftTitle.isEmpty ? "未命名文章" : draftTitle,
                                subtitle: draftSubtitle.isEmpty ? "无副标题" : draftSubtitle,
                                category: draftCategory.isEmpty ? "未分类" : draftCategory,
                                publishDateText: "今天",
                                readingTime: max(1, draftContent.count / 180),
                                tagsText: draftTagsText,
                                theme: draftTheme,
                                isFeatured: draftIsFeatured,
                                sections: [
                                    BlogSection(
                                        title: "正文",
                                        body: draftContent.isEmpty ? "暂无内容" : draftContent
                                    )
                                ]
                            ),
                            at: 0
                        )
                        posts = next

                        draftTitle = ""
                        draftSubtitle = ""
                        draftCategory = ""
                        draftTagsText = ""
                        draftContent = ""
                        draftIsFeatured = false
                        draftTheme = .blue
                        isComposerPresented = false
                    }
                    .disabled(draftTitle.isEmpty || draftCategory.isEmpty || draftContent.isEmpty)
                }
            }
        }
    }

    private func storageURL() -> URL {
        (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
            .appendingPathComponent("blog-posts.json")
    }

    private func demoPosts() -> [BlogPost] {
        [
            BlogPost(
                title: "从 0 到 1 做一个更像作品集的 SwiftUI App",
                subtitle: "如何让学生项目不只是能跑，而是真的具备展示价值。",
                category: "Portfolio",
                publishDateText: "2026-03-10",
                readingTime: 6,
                tagsText: "SwiftUI, Portfolio, Design",
                theme: .blue,
                isFeatured: true,
                sections: [
                    .init(title: "为什么作品集项目很重要", body: "作品集项目能快速体现你的代码能力和产品思维。"),
                    .init(title: "我会优先展示什么", body: "我会重点展示页面结构、视觉统一性和交互细节。")
                ]
            ),
            BlogPost(
                title: "我是怎么学习 SwiftUI 页面结构设计的",
                subtitle: "把信息架构和视觉层级一起考虑，页面会更有高级感。",
                category: "Learning",
                publishDateText: "2026-03-06",
                readingTime: 5,
                tagsText: "Layout, UX, SwiftUI",
                theme: .purple,
                isFeatured: false,
                sections: [
                    .init(title: "先分内容优先级", body: "先确定主信息和次信息，页面自然会更清晰。"),
                    .init(title: "再做组件拆分", body: "拆分适度组件，便于复用和维护。")
                ]
            ),
            BlogPost(
                title: "本科生找 iOS 工作，项目里最该突出什么",
                subtitle: "不是堆技术名词，而是让人看见你的成长曲线与产品意识。",
                category: "Career",
                publishDateText: "2026-03-01",
                readingTime: 4,
                tagsText: "Career, Interview, iOS",
                theme: .green,
                isFeatured: false,
                sections: [
                    .init(title: "突出真实问题", body: "说清楚你解决了什么问题，比堆技术名词更有说服力。"),
                    .init(title: "突出工程意识", body: "目录分层、可维护性、扩展思路都很关键。")
                ]
            )
        ]
    }
}

private struct HomeTab: View {
    let posts: [BlogPost]

    private var categories: [String] {
        Array(Set(posts.map(\.category))).sorted()
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Build in public, grow in public.")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("一个面向求职展示的 SwiftUI 个人博客 Demo，用来呈现项目能力和成长轨迹。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let featured = posts.first(where: \.isFeatured) {
                            NavigationLink {
                                ArticleDetailView(post: featured)
                            } label: {
                                FeaturedCard(post: featured)
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("What I Write").font(.title3.bold())
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(categories, id: \.self) { category in
                                        TagPill(text: category)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Latest Posts").font(.title3.bold())
                            ForEach(posts.prefix(3)) { post in
                                NavigationLink {
                                    ArticleDetailView(post: post)
                                } label: {
                                    PostRow(post: post)
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
        }
    }
}

private struct ArticlesTab: View {
    let posts: [BlogPost]
    @Binding var isComposerPresented: Bool
    @Binding var postPendingDeletion: BlogPost?

    var body: some View {
        NavigationStack {
            AppBackground {
                if posts.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 42))
                            .foregroundStyle(Color.accentColor)
                        Text("还没有你自己的文章")
                            .font(.title3.bold())
                        Button("开始写作") {
                            isComposerPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(32)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("All Articles")
                                .font(.title3.bold())

                            ForEach(posts) { post in
                                NavigationLink {
                                    ArticleDetailView(post: post)
                                } label: {
                                    PostRow(post: post)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        postPendingDeletion = post
                                    } label: {
                                        Label("Delete Post", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Articles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposerPresented = true
                    } label: {
                        Label("New Post", systemImage: "square.and.pencil")
                    }
                }
            }
        }
    }
}

private struct AboutTab: View {
    let author: AuthorProfile
    let postCount: Int

    var body: some View {
        NavigationStack {
            AppBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(author.name)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text(author.role)
                                .font(.headline)
                                .foregroundStyle(Color.accentColor)
                            Text(author.bio)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(value: "\(postCount)", label: "Published Posts")
                            StatCard(value: "iOS", label: "Focus")
                            StatCard(value: "Local Drafts", label: "Storage")
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Career Goals")
                                .font(.title3.bold())
                            ForEach(author.goals, id: \.self) { goal in
                                Label(goal, systemImage: "checkmark.seal.fill")
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Skills")
                                .font(.title3.bold())
                            Text(author.skills.joined(separator: " / "))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("About Me")
        }
    }
}

private struct AppBackground<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 1.0),
                    .white,
                    Color(red: 0.95, green: 0.98, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            content
        }
    }
}

private struct FeaturedCard: View {
    let post: BlogPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FEATURED")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.9))

            Text(post.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(post.subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)

            HStack(spacing: 10) {
                Label(post.publishDateText, systemImage: "calendar")
                Label("\(post.readingTime) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.92))
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .bottomLeading)
        .background(
            LinearGradient(
                colors: post.theme.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct PostRow: View {
    let post: BlogPost

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: post.theme.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 86, height: 106)

            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(post.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Label(post.publishDateText, systemImage: "calendar")
                    Label("\(post.readingTime) min", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !post.tagsText.isEmpty {
                    Text(post.tagsText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct ArticleDetailView: View {
    let post: BlogPost

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: post.theme.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 240)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 10) {
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
                        .padding(22)
                    }

                HStack(spacing: 14) {
                    Label(post.publishDateText, systemImage: "calendar")
                    Label("\(post.readingTime) min read", systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if !post.tagsText.isEmpty {
                    Text("Tags: \(post.tagsText)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(post.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.title3.bold())
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [.white, Color(red: 0.96, green: 0.97, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BlogPost: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var subtitle: String
    var category: String
    var publishDateText: String
    var readingTime: Int
    var tagsText: String
    var theme: BlogTheme
    var isFeatured: Bool
    var sections: [BlogSection]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: String,
        publishDateText: String,
        readingTime: Int,
        tagsText: String,
        theme: BlogTheme,
        isFeatured: Bool,
        sections: [BlogSection]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.publishDateText = publishDateText
        self.readingTime = readingTime
        self.tagsText = tagsText
        self.theme = theme
        self.isFeatured = isFeatured
        self.sections = sections
    }
}

struct BlogSection: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var body: String

    init(id: UUID = UUID(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}

struct AuthorProfile {
    let name: String
    let role: String
    let bio: String
    let location: String
    let education: String
    let goals: [String]
    let skills: [String]
}

enum BlogTheme: String, CaseIterable, Identifiable, Codable {
    case blue = "Blue"
    case purple = "Purple"
    case green = "Green"
    case orange = "Orange"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .blue:
            [Color.blue, Color.blue.opacity(0.7)]
        case .purple:
            [Color.purple, Color.purple.opacity(0.7)]
        case .green:
            [Color.green, Color.green.opacity(0.7)]
        case .orange:
            [Color.orange, Color.orange.opacity(0.7)]
        }
    }
}

#Preview {
    ContentView()
}
