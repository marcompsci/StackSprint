import SwiftUI
import UniformTypeIdentifiers

// MARK: - Progress backup
//
// Progress lives only on this device (cloud sync is off), so losing or replacing
// a phone meant starting over. A backup is a small JSON file the learner saves
// wherever they like (Files, iCloud Drive, AirDrop) and restores later. Nothing
// is uploaded; importing merges, so it never deletes what's already here.

struct ProgressBackup: Codable, Equatable {
    static let currentVersion = 1

    var version = currentVersion
    var exportedAt: Date
    var completedLessons: [String]
    var practiceDays: [String]
    var quizAnswers: [String]
    var reviewCards: [String: SM2Card]
    var bookmarks: [String]
    var notes: [String: String]
    var completedMissions: [String]
    var missionDrafts: [String: String]
    /// Added after version 1 shipped; older backups simply don't have it.
    var lessonActivity: [String]? = nil

    enum BackupError: LocalizedError {
        case newerVersion, notABackup
        var errorDescription: String? {
            switch self {
            case .newerVersion: return "This backup was made by a newer version of StackSprint. Update the app, then try again."
            case .notABackup: return "That file isn't a StackSprint progress backup."
            }
        }
    }

    static func decode(_ data: Data) throws -> ProgressBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(ProgressBackup.self, from: data) else { throw BackupError.notABackup }
        guard backup.version <= currentVersion else { throw BackupError.newerVersion }
        return backup
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    var summary: String {
        "\(completedLessons.count) lessons, \(practiceDays.count) practice days, \(reviewCards.count) review cards, \(completedMissions.count) Studio missions"
    }
}

@MainActor enum ProgressBackupService {
    static let completedMissionsKey = "studio.missions.completed"

    static func missionDraftKeys() -> [String] {
        [ProjectTrack.design, .build].flatMap { StudioMission.missions(for: $0) }.map(MissionProgress.draftKey)
    }

    static func make(store: LearningStore, bookmarks: BookmarkStore) -> ProgressBackup {
        let defaults = UserDefaults.standard
        var drafts: [String: String] = [:]
        for key in missionDraftKeys() { if let draft = defaults.string(forKey: key) { drafts[key] = draft } }
        return ProgressBackup(
            exportedAt: Date(),
            completedLessons: store.completed.sorted(),
            practiceDays: store.practicedDays.sorted(),
            quizAnswers: store.correctRecallAnswers.sorted(),
            reviewCards: SM2Engine.shared.cards,
            bookmarks: bookmarks.bookmarks.sorted(),
            notes: bookmarks.notes,
            completedMissions: (defaults.stringArray(forKey: completedMissionsKey) ?? []).sorted(),
            missionDrafts: drafts,
            lessonActivity: store.lessonActivity.sorted()
        )
    }

    /// Merges a backup into this device. Never removes anything.
    static func restore(_ backup: ProgressBackup, store: LearningStore, bookmarks: BookmarkStore) {
        store.mergeFromCloud(completed: Set(backup.completedLessons),
                             practicedDays: Set(backup.practiceDays),
                             recallAnswers: Set(backup.quizAnswers))
        store.mergeLessonActivity(Set(backup.lessonActivity ?? []))
        SM2Engine.shared.merge(backup.reviewCards)
        bookmarks.merge(bookmarks: Set(backup.bookmarks), notes: backup.notes)
        let defaults = UserDefaults.standard
        let missions = Set(defaults.stringArray(forKey: completedMissionsKey) ?? []).union(backup.completedMissions)
        defaults.set(missions.sorted(), forKey: completedMissionsKey)
        let allowed = Set(missionDraftKeys())
        for (key, draft) in backup.missionDrafts where allowed.contains(key) && defaults.string(forKey: key) == nil {
            defaults.set(draft, forKey: key)
        }
    }
}

extension ProgressBackupService {
    /// Erases learning progress on this device. Free-build projects, settings, earned
    /// achievements and season badges are kept.
    static func erase(store: LearningStore, bookmarks: BookmarkStore) {
        store.eraseProgress()
        SM2Engine.shared.eraseAll()
        bookmarks.eraseAll()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: completedMissionsKey)
        for key in missionDraftKeys() { defaults.removeObject(forKey: key) }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("draft.") || key.hasPrefix("celebrated.track.") {
            defaults.removeObject(forKey: key)
        }
        for track in [ProjectTrack.design, .build] {
            MissionProgress.setCurrentIndex(0, for: track)
            for mission in StudioMission.missions(for: track) { defaults.removeObject(forKey: MissionProgress.passingKey(mission)) }
        }
    }
}

struct ProgressBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

// MARK: - Account section

struct ProgressBackupSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var bookmarks: BookmarkStore
    @State private var exporting = false
    @State private var importing = false
    @State private var document: ProgressBackupDocument?
    @State private var pending: ProgressBackup?
    @State private var message: String?
    @State private var confirmingErase = false

    private var fileName: String {
        "StackSprint-progress-\(Date().formatted(.iso8601.year().month().day()))"
    }

    var body: some View {
        Section {
            Button("Save a backup file", systemImage: "square.and.arrow.up") {
                do {
                    document = ProgressBackupDocument(data: try ProgressBackupService.make(store: store, bookmarks: bookmarks).encoded())
                    exporting = true
                } catch {
                    message = "Couldn't make the backup: \(error.localizedDescription)"
                }
            }
            Button("Restore from a backup", systemImage: "square.and.arrow.down") { importing = true }
            Button("Erase progress on this device", systemImage: "trash", role: .destructive) { confirmingErase = true }
            if let message { Text(message).font(.footnote).foregroundStyle(.secondary) }
        } header: {
            Text("Your progress")
        } footer: {
            Text("Your progress is saved only on this device. A backup file keeps lessons, streak days, reviews, bookmarks and Studio missions safe when you change phones. Restoring adds to what's here and never deletes anything.")
        }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: fileName) { result in
            switch result {
            case .success: message = "Backup saved."
            case .failure(let error): message = "Couldn't save the backup: \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                do {
                    pending = try ProgressBackup.decode(Data(contentsOf: url))
                } catch {
                    message = error.localizedDescription
                }
            case .failure(let error):
                message = "Couldn't open the file: \(error.localizedDescription)"
            }
        }
        .confirmationDialog("Erase your progress on this device?", isPresented: $confirmingErase, titleVisibility: .visible) {
            Button("Erase progress", role: .destructive) {
                ProgressBackupService.erase(store: store, bookmarks: bookmarks)
                message = "Progress erased. Lessons, streak, reviews, bookmarks and Studio missions start fresh."
            }
        } message: {
            Text("Lessons, streak days, quiz answers, reviews, bookmarks, notes and Studio mission code are deleted. This can't be undone, so save a backup file first if you might want them back. Free-build projects and earned badges stay.")
        }
        .alert("Restore this backup?", isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
               presenting: pending) { backup in
            Button("Restore") {
                ProgressBackupService.restore(backup, store: store, bookmarks: bookmarks)
                message = "Restored \(backup.summary)."
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: { backup in
            Text("Saved \(backup.exportedAt.formatted(date: .abbreviated, time: .shortened)): \(backup.summary). It's added to the progress already on this device.")
        }
    }
}
