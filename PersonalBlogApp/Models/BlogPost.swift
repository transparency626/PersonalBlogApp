import Foundation

struct BlogPost: Identifiable, Hashable, Codable {
    struct Section: Identifiable, Hashable, Codable {
        let id: UUID
        let title: String
        let body: String

        init(id: UUID = UUID(), title: String, body: String) {
            self.id = id
            self.title = title
            self.body = body
        }
    }

    let id: UUID
    let title: String
    let subtitle: String
    let category: String
    let publishDate: Date
    let readingTime: Int
    let tags: [String]
    let coverGradient: [String]
    let isFeatured: Bool
    let sections: [Section]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        category: String,
        publishDate: Date,
        readingTime: Int,
        tags: [String],
        coverGradient: [String],
        isFeatured: Bool,
        sections: [Section]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.publishDate = publishDate
        self.readingTime = readingTime
        self.tags = tags
        self.coverGradient = coverGradient
        self.isFeatured = isFeatured
        self.sections = sections
    }

    var excerpt: String {
        sections.first?.body ?? subtitle
    }

    func updatingFeatured(_ isFeatured: Bool) -> BlogPost {
        BlogPost(
            id: id,
            title: title,
            subtitle: subtitle,
            category: category,
            publishDate: publishDate,
            readingTime: readingTime,
            tags: tags,
            coverGradient: coverGradient,
            isFeatured: isFeatured,
            sections: sections
        )
    }
}
