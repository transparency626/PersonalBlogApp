import Foundation

struct AuthorProfile {
    let name: String
    let role: String
    let bio: String
    let location: String
    let education: String
    let goals: [String]
    let skills: [String]
    let stats: [ProfileStat]
}

struct ProfileStat: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let value: String
}
