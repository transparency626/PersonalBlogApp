import Combine
import Foundation

final class BlogViewModel: ObservableObject {
    @Published private(set) var posts: [BlogPost]
    @Published private(set) var author: AuthorProfile = SampleData.author

    private let storageURL: URL

    init() {
        storageURL = BlogViewModel.makeStorageURL()
        posts = BlogViewModel.loadPosts(from: storageURL)
    }

    var featuredPost: BlogPost? {
        posts.first(where: \.isFeatured)
    }

    var latestPosts: [BlogPost] {
        posts.sorted { $0.publishDate > $1.publishDate }
    }

    var categories: [String] {
        Array(Set(posts.map(\.category))).sorted()
    }

    var profileStats: [ProfileStat] {
        [
            ProfileStat(label: "Published Posts", value: "\(posts.count)"),
            ProfileStat(label: "Focus", value: "iOS"),
            ProfileStat(label: "Storage", value: "Local Drafts")
        ]
    }

    func addPost(from draft: BlogPostDraft) {
        var nextPosts = posts
        if draft.isFeatured {
            nextPosts = nextPosts.map { $0.updatingFeatured(false) }
        }

        nextPosts.append(draft.makePost())
        posts = nextPosts
        savePosts()
    }

    func deletePost(_ post: BlogPost) {
        posts.removeAll { $0.id == post.id }
        savePosts()
    }

    private func savePosts() {
        do {
            let data = try JSONEncoder().encode(posts)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save posts: \(error.localizedDescription)")
        }
    }

    private static func makeStorageURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return directory.appendingPathComponent("blog-posts.json")
    }

    private static func loadPosts(from url: URL) -> [BlogPost] {
        guard
            let data = try? Data(contentsOf: url),
            let posts = try? JSONDecoder().decode([BlogPost].self, from: data),
            !posts.isEmpty
        else {
            return SampleData.posts
        }

        return posts
    }
}

struct BlogPostDraft {
    var title = ""
    var subtitle = ""
    var category = ""
    var tagsText = ""
    var content = ""
    var isFeatured = false
    var selectedTheme: BlogTheme = .ocean

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var estimatedReadingTime: Int {
        max(1, content.trimmingCharacters(in: .whitespacesAndNewlines).readingTime)
    }

    func makePost() -> BlogPost {
        let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return BlogPost(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? cleanedContent.blogSummary,
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            publishDate: .now,
            readingTime: estimatedReadingTime,
            tags: tagsText.tagList,
            coverGradient: selectedTheme.colors,
            isFeatured: isFeatured,
            sections: cleanedContent.parsedSections
        )
    }
}

enum BlogTheme: String, CaseIterable, Identifiable {
    case ocean
    case sunset
    case mint
    case violet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .mint: "Mint"
        case .violet: "Violet"
        }
    }

    var colors: [String] {
        switch self {
        case .ocean: ["#5B8CFF", "#8E5CFF"]
        case .sunset: ["#FF7A59", "#FFB457"]
        case .mint: ["#25C2A0", "#0E8CF1"]
        case .violet: ["#7B61FF", "#C15CFF"]
        }
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var readingTime: Int {
        let words = split { $0.isWhitespace || $0.isNewline }.count
        return Int(ceil(Double(words) / 220.0))
    }

    var blogSummary: String {
        let flattened = replacingOccurrences(of: "\n", with: " ")
        return String(flattened.prefix(80))
    }

    var tagList: [String] {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var parsedSections: [BlogPost.Section] {
        let blocks = components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var sections: [BlogPost.Section] = []
        var pendingTitle: String?

        for block in blocks {
            if block.hasPrefix("## ") {
                pendingTitle = String(block.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                continue
            }

            let title = pendingTitle ?? (sections.isEmpty ? "Overview" : "Section \(sections.count + 1)")
            sections.append(.init(title: title, body: block))
            pendingTitle = nil
        }

        if sections.isEmpty {
            sections = [.init(title: "Overview", body: self)]
        }

        return sections
    }
}

enum SampleData {
    static let author = AuthorProfile(
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
            "MVVM",
            "UI/UX Thinking",
            "REST API",
            "Git/GitHub",
            "Figma Handoff",
            "Animation Polish"
        ],
        stats: []
    )

    static let posts: [BlogPost] = [
        BlogPost(
            title: "从 0 到 1 做一个更像作品集的 SwiftUI App",
            subtitle: "如何让学生项目不只是能跑，而是真的具备展示价值。",
            category: "Portfolio",
            publishDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)) ?? .now,
            readingTime: 6,
            tags: ["SwiftUI", "Portfolio", "Design"],
            coverGradient: ["#5B8CFF", "#8E5CFF"],
            isFeatured: true,
            sections: [
                .init(title: "为什么作品集项目很重要", body: "对本科生来说，作品集项目不是加分项，而是让面试官快速判断你是否真的具备移动端开发思维的核心材料。一个相当像样的项目，应该同时体现你对代码结构、视觉层次、信息组织和用户体验的理解。"),
                .init(title: "我会优先展示什么", body: "如果项目只是把接口通了、页面堆出来，面试官很难记住你。相反，一个有清晰首页、有统一视觉、能讲出设计取舍和工程结构的应用，会显得成熟很多。这也是我想把个人博客做成 App 的原因。"),
                .init(title: "适合学生阶段的实现方式", body: "用 SwiftUI 做这样一个博客型应用很合适。它能够快速构建现代界面，也方便展示组件化思路、状态管理方式和基础动画处理。即使先用本地 mock 数据，也完全可以把整体完成度做得很高。")
            ]
        ),
        BlogPost(
            title: "我是怎么学习 SwiftUI 页面结构设计的",
            subtitle: "把信息架构和视觉层级一起考虑，页面会更有高级感。",
            category: "Learning",
            publishDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 6)) ?? .now,
            readingTime: 5,
            tags: ["Layout", "UX", "SwiftUI"],
            coverGradient: ["#FF7A59", "#FFB457"],
            isFeatured: false,
            sections: [
                .init(title: "先分内容优先级", body: "我做页面时会先区分核心内容、辅助内容和装饰信息。比如文章标题和摘要必须第一眼看清，标签和时间属于辅助信息，而背景渐变和卡片阴影负责营造气质。"),
                .init(title: "再做组件拆分", body: "页面一旦拆成 Hero、Section Header、Card 这些小组件，后面复用和调样式都会轻松很多。对于求职项目来说，这也能向面试官展示你不是在写一次性页面。"),
                .init(title: "最后补细节", body: "细节通常决定最终质感，比如留白、圆角、字体粗细、阴影浓度，以及交互反馈是否克制。SwiftUI 的优势在于这些部分可以快速迭代和对比。")
            ]
        ),
        BlogPost(
            title: "本科生找 iOS 工作，项目里最该突出什么",
            subtitle: "不是堆技术名词，而是让人看见你的成长曲线与产品意识。",
            category: "Career",
            publishDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? .now,
            readingTime: 4,
            tags: ["Career", "Interview", "iOS"],
            coverGradient: ["#25C2A0", "#0E8CF1"],
            isFeatured: false,
            sections: [
                .init(title: "突出真实问题", body: "如果你能说清楚项目想解决什么问题、用户是谁、为什么这样设计，就已经比单纯展示技术栈更有说服力。企业希望看到的是思考方式，而不仅是 API 调用记录。"),
                .init(title: "突出工程意识", body: "哪怕是一个小型博客应用，也可以体现状态管理、目录分层、可复用组件、资源组织和后续扩展思路。这些都会让你显得更像一名能协作的开发者。"),
                .init(title: "突出持续打磨", body: "作品最好不是一次性提交，而是能够持续更新的。你可以后续接入真实后端、增加搜索和收藏、做深色模式、补单元测试。这样项目就会跟着你的成长一起进化。")
            ]
        )
    ]

    private static let calendar = Calendar(identifier: .gregorian)
}
