import Combine
import Foundation

/// 博客页面的数据与业务逻辑中心，负责：
/// 1）管理文章列表与作者信息；
/// 2）提供首页需要的派生数据（精选、最新、分类、统计）；
/// 3）新增/删除文章并落盘到本地 JSON。
final class BlogViewModel: ObservableObject {
    /// 对外发布的文章数组；`private(set)` 表示外部只能读，不能直接写。
    @Published private(set) var posts: [BlogPost]
    /// 对外发布的作者资料；默认使用示例作者数据。
    @Published private(set) var author: AuthorProfile = SampleData.author

    /// 本地存储文件地址（`blog-posts.json`）。
    private let storageURL: URL

    /// 初始化时先计算存储路径，再尝试读取本地文章；读取失败则回退到示例数据。
    init() {
        // 生成文档目录下的持久化文件路径。
        storageURL = BlogViewModel.makeStorageURL()
        // 从本地文件加载文章；若文件不存在/解码失败/为空，会使用 SampleData。
        posts = BlogViewModel.loadPosts(from: storageURL)
    }

    /// 当前精选文章：查找 `isFeatured == true` 的第一篇。
    var featuredPost: BlogPost? {
        posts.first(where: \.isFeatured)
    }

    /// 最新文章列表：按发布时间降序排序（新 -> 旧）。
    var latestPosts: [BlogPost] {
        posts.sorted { $0.publishDate > $1.publishDate }
    }

    /// 所有分类：先映射分类，再去重，最后按字典序排序。
    var categories: [String] {
        Array(Set(posts.map(\.category))).sorted()
    }

    /// 个人主页统计区数据。
    var profileStats: [ProfileStat] {
        [
            // label: 统计项名称；value: 展示值（字符串）。
            ProfileStat(label: "Published Posts", value: "\(posts.count)"),
            // label: 统计项名称；value: 当前内容聚焦方向。
            ProfileStat(label: "Focus", value: "iOS"),
            // label: 统计项名称；value: 存储策略说明。
            ProfileStat(label: "Storage", value: "Local Drafts")
        ]
    }

    /// 把草稿转成正式文章并添加到列表。
    /// - Parameter draft: 新文章草稿（标题、正文、标签、主题等来自这里）。
    func addPost(from draft: BlogPostDraft) {
        // 先复制一份当前数组，避免中途多次触发 `@Published` 通知。
        var nextPosts = posts
        // 若新稿被设为精选，则先把现有文章全部取消精选，保证“最多一篇精选”。
        if draft.isFeatured {
            nextPosts = nextPosts.map { $0.updatingFeatured(false) }
        }

        // 把草稿转换成正式 `BlogPost` 并追加到数组末尾。
        nextPosts.append(draft.makePost())
        // 一次性回写，触发 UI 刷新。
        posts = nextPosts
        // 立即持久化，避免应用退出导致新增丢失。
        savePosts()
    }

    /// 删除指定文章并持久化。
    /// - Parameter post: 要删除的文章对象（根据 `id` 精确匹配）。
    func deletePost(_ post: BlogPost) {
        // 过滤掉 id 相同的项；其余保留。
        posts.removeAll { $0.id == post.id }
        // 删除后立即落盘。
        savePosts()
    }

    /// 将当前 `posts` 编码为 JSON 并写入本地文件。
    private func savePosts() {
        do {
            // 编码数组为 Data。
            let data = try JSONEncoder().encode(posts)
            // 原子写入：先写临时文件再替换，降低文件损坏风险。
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            // Debug 阶段提醒保存失败；生产环境可替换为日志上报。
            assertionFailure("Failed to save posts: \(error.localizedDescription)")
        }
    }

    /// 构建本地存储地址：
    /// 优先使用文档目录，拿不到时回退到临时目录。
    private static func makeStorageURL() -> URL {
        // documents 目录通常用于用户数据持久化。
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            // 兜底：极端情况下使用临时目录。
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        // 最终文件名固定为 `blog-posts.json`。
        return directory.appendingPathComponent("blog-posts.json")
    }

    /// 从本地 JSON 文件读取文章列表。
    /// - Parameter url: JSON 文件路径。
    /// - Returns: 解码成功且非空则返回该数组；否则回退示例数据。
    private static func loadPosts(from url: URL) -> [BlogPost] {
        guard
            // 读取文件字节。
            let data = try? Data(contentsOf: url),
            // 把 JSON 反序列化成 `[BlogPost]`。
            let posts = try? JSONDecoder().decode([BlogPost].self, from: data),
            // 防止加载到空数组导致首页无内容。
            !posts.isEmpty
        else {
            // 回退到内置示例文章。
            return SampleData.posts
        }

        // 返回本地真实数据。
        return posts
    }
}

/// 新建文章时的“可编辑草稿模型”。
struct BlogPostDraft {
    /// 文章主标题。
    var title = ""
    /// 文章副标题。
    var subtitle = ""
    /// 分类（如 Learning/Career）。
    var category = ""
    /// 标签输入框原始文本（逗号分隔）。
    var tagsText = ""
    /// 正文原始文本（可能含 markdown 风格小标题）。
    var content = ""
    /// 是否设为精选文章。
    var isFeatured = false
    /// 封面主题配色。
    var selectedTheme: BlogTheme = .ocean

    /// 草稿是否满足最小发布条件：
    /// 标题、分类、正文去空白后都不能为空。
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 预估阅读时长（分钟）：至少 1 分钟。
    var estimatedReadingTime: Int {
        max(1, content.trimmingCharacters(in: .whitespacesAndNewlines).readingTime)
    }

    /// 将草稿转换成可展示/可持久化的 `BlogPost`。
    func makePost() -> BlogPost {
        // 统一清洗正文两端空白，后续摘要与分段都使用清洗后的内容。
        let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return BlogPost(
            // title: 主标题（去掉首尾空白和换行）。
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            // subtitle: 若副标题为空，则自动回退为正文摘要（前 80 字符）。
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? cleanedContent.blogSummary,
            // category: 分类（去掉首尾空白和换行）。
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            // publishDate: 发布时间使用当前时间。
            publishDate: .now,
            // readingTime: 预估阅读时长（分钟）。
            readingTime: estimatedReadingTime,
            // tags: 将逗号分隔文本解析成标签数组并清洗空项。
            tags: tagsText.tagList,
            // coverGradient: 从主题枚举取两段渐变色。
            coverGradient: selectedTheme.colors,
            // isFeatured: 是否作为首页精选。
            isFeatured: isFeatured,
            // sections: 将正文按规则拆分为段落结构。
            sections: cleanedContent.parsedSections
        )
    }
}

/// 博客封面主题枚举：决定展示文案和渐变配色。
enum BlogTheme: String, CaseIterable, Identifiable {
    /// 海洋蓝紫主题。
    case ocean
    /// 日落橙黄主题。
    case sunset
    /// 薄荷蓝绿主题。
    case mint
    /// 紫罗兰主题。
    case violet

    /// `Identifiable` 要求的稳定标识，这里直接使用 rawValue。
    var id: String { rawValue }

    /// UI 展示名称。
    var title: String {
        switch self {
        // 每个 case 返回对应的可读标题。
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .mint: "Mint"
        case .violet: "Violet"
        }
    }

    /// 主题渐变颜色（十六进制字符串数组，通常两段）。
    var colors: [String] {
        switch self {
        // 每个主题提供两种颜色用于线性渐变。
        case .ocean: ["#5B8CFF", "#8E5CFF"]
        case .sunset: ["#FF7A59", "#FFB457"]
        case .mint: ["#25C2A0", "#0E8CF1"]
        case .violet: ["#7B61FF", "#C15CFF"]
        }
    }
}

/// 仅在本文件内使用的字符串工具扩展。
private extension String {
    /// 去除首尾空白后，若为空则返回 `nil`，否则返回清洗后的字符串。
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// 按约 220 WPM（每分钟词数）估算阅读时长，向上取整。
    var readingTime: Int {
        // 以空白/换行为分隔统计“词”数量。
        let words = split { $0.isWhitespace || $0.isNewline }.count
        // `ceil` 保证有小数时进位，例如 1.1 分钟 -> 2 分钟。
        return Int(ceil(Double(words) / 220.0))
    }

    /// 生成简短摘要：把换行转空格后截取前 80 个字符。
    var blogSummary: String {
        // 先打平换行，避免摘要出现断行。
        let flattened = replacingOccurrences(of: "\n", with: " ")
        // 截断到固定长度，防止副标题过长。
        return String(flattened.prefix(80))
    }

    /// 将逗号分隔标签文本解析为数组，并清洗空白与空值。
    var tagList: [String] {
        split(separator: ",")
            // 去掉每个标签首尾空白。
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            // 过滤空字符串，避免无效标签。
            .filter { !$0.isEmpty }
    }

    /// 把长文本解析为文章段落：
    /// - 以双换行分块；
    /// - `## ` 前缀视为下一段标题；
    /// - 若无标题则自动生成默认标题。
    var parsedSections: [BlogPost.Section] {
        // 按段落空行分割，再清洗空白并移除空块。
        let blocks = components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // 结果段落数组。
        var sections: [BlogPost.Section] = []
        // 暂存待应用的标题（来自上一个 `## ` 块）。
        var pendingTitle: String?

        // 逐块解析。
        for block in blocks {
            // `## ` 开头代表标题块，不直接产出正文段。
            if block.hasPrefix("## ") {
                // 去掉前缀后得到标题文本。
                pendingTitle = String(block.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                continue
            }

            // 优先使用待定标题；没有就生成默认标题。
            let title = pendingTitle ?? (sections.isEmpty ? "Overview" : "Section \(sections.count + 1)")
            // 组装一个段落对象（title + body）。
            sections.append(.init(title: title, body: block))
            // 消费掉待定标题，避免影响下一段。
            pendingTitle = nil
        }

        // 若解析后仍为空，说明原文没有有效分块：整篇作为 Overview。
        if sections.isEmpty {
            sections = [.init(title: "Overview", body: self)]
        }

        // 返回最终段落结果。
        return sections
    }
}

/// 应用内置示例数据（作者信息 + 默认文章列表）。
enum SampleData {
    /// 示例作者资料。
    static let author = AuthorProfile(
        // name: 显示名称。
        name: "Chen",
        // role: 角色/身份描述。
        role: "Aspiring iOS Developer",
        // bio: 个人简介长文本。
        bio: "本科在读，主攻 SwiftUI、产品体验和移动端交互设计。我希望把学习过程、项目拆解和开发思考沉淀成高质量内容，让作品本身也能成为简历的一部分。",
        // location: 地理位置。
        location: "China",
        // education: 教育背景。
        education: "Computer Science Undergraduate",
        // goals: 目标列表（字符串数组）。
        goals: [
            "找到一份 iOS 开发实习或校招岗位",
            "持续打磨 SwiftUI、网络层、架构设计能力",
            "做出真正有审美和完成度的移动端作品"
        ],
        // skills: 技能关键词列表。
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
        // stats: 统计项；此处置空，通常由 ViewModel 动态计算。
        stats: []
    )

    /// 示例文章数组（首次启动或本地数据缺失时使用）。
    static let posts: [BlogPost] = [
        BlogPost(
            // title: 文章标题。
            title: "从 0 到 1 做一个更像作品集的 SwiftUI App",
            // subtitle: 文章副标题。
            subtitle: "如何让学生项目不只是能跑，而是真的具备展示价值。",
            // category: 所属分类。
            category: "Portfolio",
            // publishDate: 发布时间；优先用公历日期构造，失败则回退当前时间。
            publishDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)) ?? .now,
            // readingTime: 预估阅读时长（分钟）。
            readingTime: 6,
            // tags: 标签数组。
            tags: ["SwiftUI", "Portfolio", "Design"],
            // coverGradient: 封面渐变色数组。
            coverGradient: ["#5B8CFF", "#8E5CFF"],
            // isFeatured: 是否首页精选。
            isFeatured: true,
            // sections: 正文分段数组（每段由标题与正文组成）。
            sections: [
                // title: 段落标题；body: 段落正文。
                .init(title: "为什么作品集项目很重要", body: "对本科生来说，作品集项目不是加分项，而是让面试官快速判断你是否真的具备移动端开发思维的核心材料。一个相当像样的项目，应该同时体现你对代码结构、视觉层次、信息组织和用户体验的理解。"),
                // title: 段落标题；body: 段落正文。
                .init(title: "我会优先展示什么", body: "如果项目只是把接口通了、页面堆出来，面试官很难记住你。相反，一个有清晰首页、有统一视觉、能讲出设计取舍和工程结构的应用，会显得成熟很多。这也是我想把个人博客做成 App 的原因。"),
                // title: 段落标题；body: 段落正文。
                .init(title: "适合学生阶段的实现方式", body: "用 SwiftUI 做这样一个博客型应用很合适。它能够快速构建现代界面，也方便展示组件化思路、状态管理方式和基础动画处理。即使先用本地 mock 数据，也完全可以把整体完成度做得很高。")
            ]
        ),
        BlogPost(
            // title: 文章标题。
            title: "我是怎么学习 SwiftUI 页面结构设计的",
            // subtitle: 文章副标题。
            subtitle: "把信息架构和视觉层级一起考虑，页面会更有高级感。",
            // category: 所属分类。
            category: "Learning",
            // publishDate: 发布时间。
            publishDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 6)) ?? .now,
            // readingTime: 预估阅读时长（分钟）。
            readingTime: 5,
            // tags: 标签数组。
            tags: ["Layout", "UX", "SwiftUI"],
            // coverGradient: 封面渐变色数组。
            coverGradient: ["#FF7A59", "#FFB457"],
            // isFeatured: 是否首页精选。
            isFeatured: false,
            // sections: 正文分段数组。
            sections: [
                // title: 段落标题；body: 段落正文。
                .init(title: "先分内容优先级", body: "我做页面时会先区分核心内容、辅助内容和装饰信息。比如文章标题和摘要必须第一眼看清，标签和时间属于辅助信息，而背景渐变和卡片阴影负责营造气质。"),
                // title: 段落标题；body: 段落正文。
                .init(title: "再做组件拆分", body: "页面一旦拆成 Hero、Section Header、Card 这些小组件，后面复用和调样式都会轻松很多。对于求职项目来说，这也能向面试官展示你不是在写一次性页面。"),
                // title: 段落标题；body: 段落正文。
                .init(title: "最后补细节", body: "细节通常决定最终质感，比如留白、圆角、字体粗细、阴影浓度，以及交互反馈是否克制。SwiftUI 的优势在于这些部分可以快速迭代和对比。")
            ]
        ),
        BlogPost(
            // title: 文章标题。
            title: "本科生找 iOS 工作，项目里最该突出什么",
            // subtitle: 文章副标题。
            subtitle: "不是堆技术名词，而是让人看见你的成长曲线与产品意识。",
            // category: 所属分类。
            category: "Career",
            // publishDate: 发布时间。
            publishDate: calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? .now,
            // readingTime: 预估阅读时长（分钟）。
            readingTime: 4,
            // tags: 标签数组。
            tags: ["Career", "Interview", "iOS"],
            // coverGradient: 封面渐变色数组。
            coverGradient: ["#25C2A0", "#0E8CF1"],
            // isFeatured: 是否首页精选。
            isFeatured: false,
            // sections: 正文分段数组。
            sections: [
                // title: 段落标题；body: 段落正文。
                .init(title: "突出真实问题", body: "如果你能说清楚项目想解决什么问题、用户是谁、为什么这样设计，就已经比单纯展示技术栈更有说服力。企业希望看到的是思考方式，而不仅是 API 调用记录。"),
                // title: 段落标题；body: 段落正文。
                .init(title: "突出工程意识", body: "哪怕是一个小型博客应用，也可以体现状态管理、目录分层、可复用组件、资源组织和后续扩展思路。这些都会让你显得更像一名能协作的开发者。"),
                // title: 段落标题；body: 段落正文。
                .init(title: "突出持续打磨", body: "作品最好不是一次性提交，而是能够持续更新的。你可以后续接入真实后端、增加搜索和收藏、做深色模式、补单元测试。这样项目就会跟着你的成长一起进化。")
            ]
        )
    ]

    /// 用于构造示例文章日期的公历日历对象。
    private static let calendar = Calendar(identifier: .gregorian)
}
