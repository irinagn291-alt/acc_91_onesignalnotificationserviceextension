import Foundation

enum VaultMoodCatalog {
    struct SubjectPick: Identifiable, Hashable, Sendable {
        var id: String { slug }
        var slug: String
        var title: String
        var icon: String
    }

    struct MoodPick: Identifiable, Hashable, Sendable {
        var id: String { key }
        var key: String
        var title: String
        var icon: String
        var subjectSlug: String
    }

    static let discoverSubjects: [SubjectPick] = Array(subjects.prefix(8))

    static let moods: [MoodPick] = [
        MoodPick(key: "cozy", title: "Cozy", icon: "cup.and.saucer.fill", subjectSlug: "romance"),
        MoodPick(key: "adventure", title: "Adventure", icon: "figure.hiking", subjectSlug: "adventure"),
        MoodPick(key: "curious", title: "Curious", icon: "brain", subjectSlug: "science"),
        MoodPick(key: "romantic", title: "Romantic", icon: "heart.fill", subjectSlug: "romance"),
        MoodPick(key: "dark", title: "Dark", icon: "cloud.bolt.fill", subjectSlug: "horror"),
        MoodPick(key: "thoughtful", title: "Thoughtful", icon: "lightbulb.fill", subjectSlug: "philosophy"),
        MoodPick(key: "inspired", title: "Inspired", icon: "sparkles", subjectSlug: "biography"),
        MoodPick(key: "light", title: "Light read", icon: "face.smiling", subjectSlug: "young-adult-fiction"),
    ]

    static let subjects: [SubjectPick] = [
        SubjectPick(slug: "fantasy", title: "Fantasy", icon: "wand.and.stars"),
        SubjectPick(slug: "romance", title: "Romance", icon: "heart.fill"),
        SubjectPick(slug: "science_fiction", title: "Sci-Fi", icon: "moon.stars.fill"),
        SubjectPick(slug: "mystery", title: "Mystery", icon: "magnifyingglass.circle.fill"),
        SubjectPick(slug: "horror", title: "Horror", icon: "cloud.bolt.fill"),
        SubjectPick(slug: "history", title: "History", icon: "scroll.fill"),
        SubjectPick(slug: "biography", title: "Biography", icon: "person.crop.circle"),
        SubjectPick(slug: "philosophy", title: "Philosophy", icon: "lightbulb.fill"),
        SubjectPick(slug: "psychology", title: "Psychology", icon: "brain"),
        SubjectPick(slug: "business", title: "Business", icon: "briefcase.fill"),
        SubjectPick(slug: "poetry", title: "Poetry", icon: "pencil.and.outline"),
        SubjectPick(slug: "classics", title: "Classics", icon: "books.vertical.fill"),
        SubjectPick(slug: "adventure", title: "Adventure", icon: "figure.hiking"),
        SubjectPick(slug: "young-adult-fiction", title: "Young Adult", icon: "star.fill"),
        SubjectPick(slug: "science", title: "Science", icon: "atom"),
        SubjectPick(slug: "art", title: "Art", icon: "paintbrush.fill"),
    ]
}
