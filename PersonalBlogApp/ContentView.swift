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
    @State private var draftTheme: BlogTheme = .ocean

    private let author = AuthorProfile(
        name: "Chen",
        role: "Aspiring iOS Developer",
        bio: "本科在读，主攻 SwiftUI、产品体验和移动端交互设计。我希望把学习过程、项目拆解和开发思考沉淀成高质量内容，让作品本身也能成为简历的一部分。",
        location: "China",
        education: "Computer Science Undergraduate",
        goals: [
            "找到一份 iOS 开发实习或校招岗位",
            "持续打磨 SwiftUI、网络层、架构设计能力",
            "做出真正有审美和完成度的移动端作品"
        ],
        skills: [
            "Swift",
            "SwiftUI",
            "UI/UX Thinking",
            "REST API",
            "Git/GitHub",
            "Figma Handoff"
        ]
    )

    private var sortedPosts: [BlogPost] {
        posts.sorted { $0.publishDate > $1.publishDate }
    }

    private var categories: [String] {
        Array(Set(posts.map(\.category))).sorted()
    }

    var body: some View {
        TabView {
            HomeTabView(posts: posts, categories: categories, sortedPosts: sortedPosts)
                .tabItem { Label("Home", systemImage: "house.fill") }

            ArticlesTabView(
                posts: posts,
                sortedPosts: sortedPosts,
                isComposerPresented: $isComposerPresented,
                postPendingDeletion: $postPendingDeletion
            )
            .tabItem { Label("Articles", systemImage: "newspaper.fill") }

            AboutTabView(author: author, postCount: posts.count)
                .tabItem { Label("About", systemImage: "person.fill") }
        }
        .tint(Color.accentColor)
        .sheet(isPresented: $isComposerPresented) {
            PostComposerSheet(
                isComposerPresented: $isComposerPresented,
                posts: $posts,
                draftTitle: $draftTitle,
                draftSubtitle: $draftSubtitle,
                draftCategory: $draftCategory,
                draftTagsText: $draftTagsText,
                draftContent: $draftContent,
                draftIsFeatured: $draftIsFeatured,
                draftTheme: $draftTheme
            )
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
            let fileURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
                .appendingPathComponent("blog-posts.json")
            if let data = try? Data(contentsOf: fileURL),
               let decoded = try? JSONDecoder().decode([BlogPost].self, from: data),
               !decoded.isEmpty {
                posts = decoded
            } else {
                posts = [
                    BlogPost(
                        title: "从 0 到 1 做一个更像作品集的 SwiftUI App",
                        subtitle: "如何让学生项目不只是能跑，而是真的具备展示价值。",
                        category: "Portfolio",
                        publishDate: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 3, day: 10)) ?? .now,
                        readingTime: 6,
                        tags: ["SwiftUI", "Portfolio", "Design"],
                        theme: .ocean,
                        isFeatured: true,
                        sections: [
                            .init(title: "为什么作品集项目很重要", body: "对本科生来说，作品集项目不是加分项，而是让面试官快速判断你是否真的具备移动端开发思维的核心材料。"),
                            .init(title: "我会优先展示什么", body: "项目不只是能跑，更要有清晰的信息结构和视觉层次。"),
                            .init(title: "适合学生阶段的实现方式", body: "SwiftUI 很适合快速搭建高完成度的博客展示应用。")
                        ]
                    ),
                    BlogPost(
                        title: "我是怎么学习 SwiftUI 页面结构设计的",
                        subtitle: "把信息架构和视觉层级一起考虑，页面会更有高级感。",
                        category: "Learning",
                        publishDate: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 3, day: 6)) ?? .now,
                        readingTime: 5,
                        tags: ["Layout", "UX", "SwiftUI"],
                        theme: .sunset,
                        isFeatured: false,
                        sections: [
                            .init(title: "先分内容优先级", body: "先拆核心信息和辅助信息，页面会自然清爽。"),
                            .init(title: "再做组件拆分", body: "组件化可以减少重复，让后续维护更稳。")
                        ]
                    ),
                    BlogPost(
                        title: "本科生找 iOS 工作，项目里最该突出什么",
                        subtitle: "不是堆技术名词，而是让人看见你的成长曲线与产品意识。",
                        category: "Career",
                        publishDate: Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? .now,
                        readingTime: 4,
                        tags: ["Career", "Interview", "iOS"],
                        theme: .mint,
                        isFeatured: false,
                        sections: [
                            .init(title: "突出真实问题", body: "说明项目解决了什么、为什么这样做，比堆技术名词更有说服力。"),
                            .init(title: "突出工程意识", body: "目录分层、状态管理、可复用性都能体现工程能力。")
                        ]
                    )
                ]
            }
        }
        .onChange(of: posts) { _, value in
            let fileURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
                .appendingPathComponent("blog-posts.json")
            if let data = try? JSONEncoder().encode(value) {
                try? data.write(to: fileURL, options: [.atomic])
            }
        }
    }
}

private struct HomeTabView: View {
    let posts: [BlogPost]
    let categories: [String]
    let sortedPosts: [BlogPost]

    var body: some View {
        NavigationStack {
            AppGradientBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Build in public, grow in public.")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
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

                        if let featured = posts.first(where: \.isFeatured) {
                            NavigationLink {
                                ArticleDetailView(post: featured)
                            } label: {
                                FeaturedCard(post: featured)
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("What I Write").font(.title3.bold())
                                Text("把学习记录、产品思考和项目拆解整理成可展示的博客内容。")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        TagChip(text: category)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Latest Posts").font(.title3.bold())
                                Text("最新更新的文章会在这里展示。")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(sortedPosts.prefix(3)) { post in
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

private struct ArticlesTabView: View {
    let posts: [BlogPost]
    let sortedPosts: [BlogPost]
    @Binding var isComposerPresented: Bool
    @Binding var postPendingDeletion: BlogPost?

    var body: some View {
        NavigationStack {
            AppGradientBackground {
                if posts.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 42))
                            .foregroundStyle(Color.accentColor)
                        Text("还没有你自己的文章").font(.title3.bold())
                        Text("点右上角的写作按钮，发布第一篇内容。写完后会自动保存到本地。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("开始写作") {
                            isComposerPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(32)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("All Articles").font(.title3.bold())
                                Text("现在这里已经不只是展示了，你可以直接新增并保存自己的博客内容。")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(sortedPosts) { post in
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

private struct AboutTabView: View {
    let author: AuthorProfile
    let postCount: Int

    var body: some View {
        NavigationStack {
            AppGradientBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(author.name).font(.system(size: 34, weight: .bold, design: .rounded))
                            Text(author.role).font(.headline).foregroundStyle(Color.accentColor)
                            Text(author.bio).font(.body).foregroundStyle(.secondary).lineSpacing(6)
                            HStack(spacing: 16) {
                                Label(author.education, systemImage: "graduationcap")
                                Label(author.location, systemImage: "mappin.and.ellipse")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(value: "\(postCount)", title: "Published Posts")
                            StatCard(value: "iOS", title: "Focus")
                            StatCard(value: "Local Drafts", title: "Storage")
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Career Goals").font(.title3.bold())
                            Text("我希望通过持续做项目，把学习成果变成可验证的能力。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ForEach(author.goals, id: \.self) { goal in
                                Label(goal, systemImage: "checkmark.seal.fill")
                                    .font(.subheadline)
                            }
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Skills").font(.title3.bold())
                            Text("当前重点积累的方向。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ForEach(stride(from: 0, to: author.skills.count, by: 3).map { index in
                                Array(author.skills[index..<min(index + 3, author.skills.count)])
                            }, id: \.self) { row in
                                HStack(spacing: 10) {
                                    ForEach(row, id: \.self) { tag in
                                        TagChip(text: tag)
                                    }
                                }
                            }
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

private struct PostComposerSheet: View {
    @Binding var isComposerPresented: Bool
    @Binding var posts: [BlogPost]
    @Binding var draftTitle: String
    @Binding var draftSubtitle: String
    @Binding var draftCategory: String
    @Binding var draftTagsText: String
    @Binding var draftContent: String
    @Binding var draftIsFeatured: Bool
    @Binding var draftTheme: BlogTheme

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $draftTitle)
                    TextField("副标题，不填会自动生成摘要", text: $draftSubtitle, axis: .vertical)
                    TextField("分类，例如 SwiftUI / Interview", text: $draftCategory)
                    TextField("标签，用英文逗号分隔", text: $draftTagsText)
                }
                Section("正文") {
                    TextEditor(text: $draftContent).frame(minHeight: 220)
                    Text("支持简单分段：用空行分开段落；如果某一行以 `## ` 开头，会被识别成新的章节标题。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                        Text("\(max(1, Int(ceil(Double(draftContent.split { $0.isWhitespace || $0.isNewline }.count) / 220.0)))) min")
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
                        let cleanTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanCategory = draftCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanContent = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanSubtitle = draftSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

                        let blocks = cleanContent
                            .components(separatedBy: "\n\n")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        var parsedSections: [BlogSection] = []
                        var pendingTitle: String?
                        for block in blocks {
                            if block.hasPrefix("## ") {
                                pendingTitle = String(block.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                            } else {
                                parsedSections.append(
                                    BlogSection(
                                        title: pendingTitle ?? (parsedSections.isEmpty ? "Overview" : "Section \(parsedSections.count + 1)"),
                                        body: block
                                    )
                                )
                                pendingTitle = nil
                            }
                        }
                        if parsedSections.isEmpty {
                            parsedSections = [.init(title: "Overview", body: cleanContent)]
                        }

                        let tags = draftTagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        let readingTime = max(1, Int(ceil(Double(cleanContent.split { $0.isWhitespace || $0.isNewline }.count) / 220.0)))
                        let autoSubtitle = String(cleanContent.replacingOccurrences(of: "\n", with: " ").prefix(80))

                        var next = posts
                        if draftIsFeatured {
                            next = next.map {
                                BlogPost(
                                    id: $0.id,
                                    title: $0.title,
                                    subtitle: $0.subtitle,
                                    category: $0.category,
                                    publishDate: $0.publishDate,
                                    readingTime: $0.readingTime,
                                    tags: $0.tags,
                                    theme: $0.theme,
                                    isFeatured: false,
                                    sections: $0.sections
                                )
                            }
                        }
                        next.append(
                            BlogPost(
                                title: cleanTitle,
                                subtitle: cleanSubtitle.isEmpty ? autoSubtitle : cleanSubtitle,
                                category: cleanCategory,
                                publishDate: .now,
                                readingTime: readingTime,
                                tags: tags,
                                theme: draftTheme,
                                isFeatured: draftIsFeatured,
                                sections: parsedSections
                            )
                        )
                        posts = next

                        draftTitle = ""
                        draftSubtitle = ""
                        draftCategory = ""
                        draftTagsText = ""
                        draftContent = ""
                        draftIsFeatured = false
                        draftTheme = .ocean
                        isComposerPresented = false
                    }
                    .disabled(
                        draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        draftCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        draftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }
}

private struct AppGradientBackground<Content: View>: View {
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

private struct TagChip: View {
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
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value).font(.title2.bold())
            Text(title).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct FeaturedCard: View {
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
            LinearGradient(colors: post.theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

private struct PostRow: View {
    let post: BlogPost

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: post.theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 92, height: 110)
                .overlay(alignment: .bottomLeading) {
                    Text(post.category)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                }
            VStack(alignment: .leading, spacing: 10) {
                Text(post.title).font(.headline).lineLimit(2)
                Text(post.subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                HStack(spacing: 12) {
                    Label(post.publishDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
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
    }
}

struct ArticleDetailView: View {
    let post: BlogPost

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 18) {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(colors: post.theme.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
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
                        Label(post.publishDate.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                        Label("\(post.readingTime) min read", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(post.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Text(post.sections.first?.body ?? post.subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(6)
                }
                .padding(20)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(post.sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title).font(.title3.bold())
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
    let id: UUID
    let title: String
    let subtitle: String
    let category: String
    let publishDate: Date
    let readingTime: Int
    let tags: [String]
    let theme: BlogTheme
    let isFeatured: Bool
    let sections: [BlogSection]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: String,
        publishDate: Date,
        readingTime: Int,
        tags: [String],
        theme: BlogTheme,
        isFeatured: Bool,
        sections: [BlogSection]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.publishDate = publishDate
        self.readingTime = readingTime
        self.tags = tags
        self.theme = theme
        self.isFeatured = isFeatured
        self.sections = sections
    }
}

struct BlogSection: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let body: String

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
    case ocean = "Ocean"
    case sunset = "Sunset"
    case mint = "Mint"
    case violet = "Violet"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .ocean: [Color(red: 0.36, green: 0.55, blue: 1.0), Color(red: 0.56, green: 0.36, blue: 1.0)]
        case .sunset: [Color(red: 1.0, green: 0.48, blue: 0.35), Color(red: 1.0, green: 0.71, blue: 0.34)]
        case .mint: [Color(red: 0.15, green: 0.76, blue: 0.63), Color(red: 0.05, green: 0.55, blue: 0.95)]
        case .violet: [Color(red: 0.48, green: 0.38, blue: 1.0), Color(red: 0.76, green: 0.36, blue: 1.0)]
        }
    }
}

#Preview {
    ContentView()
}
