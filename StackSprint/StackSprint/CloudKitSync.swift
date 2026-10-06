import CloudKit
import Combine
import SwiftUI

// MARK: - CloudKit Sync Manager

@MainActor final class CloudKitSyncManager: ObservableObject {
    static let shared = CloudKitSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    private let db = CKContainer(identifier: "iCloud.com.stacksprint.app").privateCloudDatabase
    private let recordType = "SprintProgress"
    private let recordID = CKRecord.ID(recordName: "progress-v1")

    enum SyncStatus: Equatable {
        case idle, syncing, synced, error(String)
        var label: String {
            switch self {
            case .idle:            return "Not yet synced"
            case .syncing:         return "Syncing…"
            case .synced:          return "Up to date"
            case .error(let msg):  return msg
            }
        }
        var icon: String {
            switch self {
            case .idle:    return "icloud"
            case .syncing: return "arrow.triangle.2.circlepath.icloud"
            case .synced:  return "checkmark.icloud.fill"
            case .error:   return "exclamationmark.icloud.fill"
            }
        }
        var color: Color {
            switch self {
            case .idle:    return .secondary
            case .syncing: return .blue
            case .synced:  return .mint
            case .error:   return .red
            }
        }
    }

    private init() {}

    func syncNow(store: LearningStore, bookmarks: BookmarkStore) async {
        syncStatus = .syncing
        do {
            // Try to fetch existing record; create new one if not found
            let record: CKRecord
            do {
                record = try await db.record(for: recordID)
                // Merge remote data into local store first
                mergeRemote(record: record, into: store, bookmarks: bookmarks)
            } catch let ckErr as CKError where ckErr.code == .unknownItem {
                record = CKRecord(recordType: recordType, recordID: recordID)
            }
            // Push merged local state back up
            record["completed"]     = Array(store.completed) as CKRecordValue
            record["practicedDays"] = Array(store.practicedDays) as CKRecordValue
            record["recallAnswers"] = Array(store.correctRecallAnswers) as CKRecordValue
            record["bookmarks"]     = Array(bookmarks.bookmarks) as CKRecordValue
            record["practiceXP"]    = store.practiceXP as CKRecordValue
            record["streak"]        = store.currentStreak as CKRecordValue
            try await db.save(record)
            lastSynced = Date()
            syncStatus = .synced
        } catch {
            syncStatus = .error(cloudKitMessage(error))
        }
    }

    private func mergeRemote(record: CKRecord, into store: LearningStore, bookmarks: BookmarkStore) {
        let remoteCompleted     = Set(record["completed"]     as? [String] ?? [])
        let remotePracticedDays = Set(record["practicedDays"] as? [String] ?? [])
        let remoteRecall        = Set(record["recallAnswers"] as? [String] ?? [])
        let remoteBookmarks     = Set(record["bookmarks"]     as? [String] ?? [])
        store.mergeFromCloud(
            completed: remoteCompleted,
            practicedDays: remotePracticedDays,
            recallAnswers: remoteRecall
        )
        for id in remoteBookmarks where !bookmarks.bookmarks.contains(id) {
            bookmarks.toggle(id)
        }
    }

    private func cloudKitMessage(_ error: Error) -> String {
        if let ck = error as? CKError {
            switch ck.code {
            case .notAuthenticated: return "Sign in to iCloud to sync"
            case .networkUnavailable, .networkFailure: return "No network — will retry"
            case .quotaExceeded: return "iCloud storage full"
            default: return "Sync error (\(ck.code.rawValue))"
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Sync Status Row (embed in AccountView)

struct CloudSyncSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var bookmarks: BookmarkStore
    @StateObject private var sync = CloudKitSyncManager.shared

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: sync.syncStatus.icon)
                    .foregroundStyle(sync.syncStatus.color)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sync.syncStatus.label).font(.subheadline)
                    if let date = sync.lastSynced {
                        Text("Last synced \(date.formatted(.relative(presentation: .named)))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if sync.syncStatus == .syncing {
                    ProgressView().scaleEffect(0.8)
                }
            }
            Button {
                Task { await sync.syncNow(store: store, bookmarks: bookmarks) }
            } label: {
                Label("Sync now", systemImage: "arrow.triangle.2.circlepath.icloud")
            }
            .disabled(sync.syncStatus == .syncing)
        } header: {
            Label("iCloud Sync", systemImage: "icloud")
        } footer: {
            Text("Progress, streaks, and bookmarks are merged across your devices — your best score always wins.")
        }
    }
}
