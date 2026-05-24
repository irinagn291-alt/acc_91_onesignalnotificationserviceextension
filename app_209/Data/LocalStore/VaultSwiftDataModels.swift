import Foundation
import SwiftData

@Model
final class SDVaultPreferences {
    @Attribute(.unique) var id: UUID
    var hasCompletedOnboarding: Bool
    var displayModeRaw: String

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        displayModeRaw: String = VaultDisplayMode.list.rawValue
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.displayModeRaw = displayModeRaw
    }
}

@Model
final class SDLibraryBook {
    @Attribute(.unique) var id: UUID
    var openLibraryId: String
    var workKey: String?
    var title: String
    var authorsJSON: String
    var coverID: Int?
    var coverURL: String?
    var year: Int?
    var subjectsJSON: String
    var statusRaw: String
    var currentPage: Int
    var totalPages: Int?
    var rating: Double?
    var note: String?
    var noteCreatedAt: Date?
    var noteUpdatedAt: Date?
    var addedAt: Date
    var startedAt: Date?
    var finishedAt: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        openLibraryId: String,
        workKey: String?,
        title: String,
        authorsJSON: String,
        coverID: Int?,
        coverURL: String?,
        year: Int?,
        subjectsJSON: String,
        statusRaw: String,
        currentPage: Int,
        totalPages: Int?,
        rating: Double?,
        note: String?,
        noteCreatedAt: Date?,
        noteUpdatedAt: Date?,
        addedAt: Date,
        startedAt: Date?,
        finishedAt: Date?,
        updatedAt: Date
    ) {
        self.id = id
        self.openLibraryId = openLibraryId
        self.workKey = workKey
        self.title = title
        self.authorsJSON = authorsJSON
        self.coverID = coverID
        self.coverURL = coverURL
        self.year = year
        self.subjectsJSON = subjectsJSON
        self.statusRaw = statusRaw
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.rating = rating
        self.note = note
        self.noteCreatedAt = noteCreatedAt
        self.noteUpdatedAt = noteUpdatedAt
        self.addedAt = addedAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.updatedAt = updatedAt
    }
}

@Model
final class SDProgressEvent {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var pageNumber: Int
    var totalPages: Int?
    var timestamp: Date

    init(id: UUID = UUID(), bookID: UUID, pageNumber: Int, totalPages: Int?, timestamp: Date = .now) {
        self.id = id
        self.bookID = bookID
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.timestamp = timestamp
    }
}

@Model
final class SDMoodList {
    @Attribute(.unique) var id: UUID
    var name: String
    var subject: String
    var savedAt: Date
    var bookCount: Int

    init(id: UUID = UUID(), name: String, subject: String, savedAt: Date = .now, bookCount: Int = 0) {
        self.id = id
        self.name = name
        self.subject = subject
        self.savedAt = savedAt
        self.bookCount = bookCount
    }
}

@Model
final class SDWeekPlanEntry {
    @Attribute(.unique) var id: UUID
    var dayIndex: Int
    var bookID: String
    var title: String
    var coverID: Int?
    var addedAt: Date

    init(id: UUID = UUID(), dayIndex: Int, bookID: String, title: String, coverID: Int?, addedAt: Date = .now) {
        self.id = id
        self.dayIndex = dayIndex
        self.bookID = bookID
        self.title = title
        self.coverID = coverID
        self.addedAt = addedAt
    }
}
