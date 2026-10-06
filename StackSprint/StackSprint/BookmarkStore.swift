import Combine
import SwiftUI

// MARK: - Bookmark Store

@MainActor final class BookmarkStore: ObservableObject {
    @Published private(set) var bookmarks: Set<String> = []
    @Published private(set) var notes: [String: String] = [:]

    private let bookmarksKey = "bookmarks.lessonIDs"
    private let notesKey     = "bookmarks.notes"

    init() { load() }

    func toggle(_ id: String) {
        if bookmarks.contains(id) { bookmarks.remove(id) } else { bookmarks.insert(id) }
        persist()
    }

    func isBookmarked(_ id: String) -> Bool { bookmarks.contains(id) }

    func setNote(_ text: String, for id: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notes.removeValue(forKey: id)
        } else {
            notes[id] = text
        }
        persist()
    }

    func note(for id: String) -> String { notes[id] ?? "" }

    // Lessons that are bookmarked and not yet completed — the review queue
    func reviewQueue(from lessons: [Lesson], completed: Set<String>) -> [Lesson] {
        lessons.filter { bookmarks.contains($0.id) && !completed.contains($0.id) }
    }

    // All bookmarked lessons (done + pending)
    func allBookmarked(from lessons: [Lesson]) -> [Lesson] {
        lessons.filter { bookmarks.contains($0.id) }
    }

    private func persist() {
        UserDefaults.standard.set(Array(bookmarks), forKey: bookmarksKey)
        UserDefaults.standard.set(notes, forKey: notesKey)
    }

    private func load() {
        bookmarks = Set(UserDefaults.standard.stringArray(forKey: bookmarksKey) ?? [])
        notes = UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String] ?? [:]
    }
}

// MARK: - Bookmark Button (inline in lesson cards)

struct BookmarkButton: View {
    @EnvironmentObject var bookmarks: BookmarkStore
    let lessonID: String

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                bookmarks.toggle(lessonID)
            }
        } label: {
            Image(systemName: bookmarks.isBookmarked(lessonID) ? "bookmark.fill" : "bookmark")
                .foregroundStyle(bookmarks.isBookmarked(lessonID) ? .yellow : .secondary)
                .font(.headline)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(bookmarks.isBookmarked(lessonID) ? "Remove bookmark" : "Bookmark lesson")
    }
}

// MARK: - Lesson Note Editor

struct LessonNoteEditor: View {
    @EnvironmentObject var bookmarks: BookmarkStore
    let lessonID: String
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("MY NOTE", systemImage: "pencil.line").font(.caption.bold()).foregroundStyle(.secondary)
            TextField("Add a note…", text: $text, axis: .vertical)
                .lineLimit(2...6)
                .font(.subheadline)
                .focused($focused)
                .onChange(of: text) { _, value in bookmarks.setNote(value, for: lessonID) }
        }
        .onAppear { text = bookmarks.note(for: lessonID) }
    }
}

// MARK: - Review Queue Section (embed in LearnView)

struct ReviewQueueSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var bookmarks: BookmarkStore
    @State private var selectedID: String?

    private var queue: [Lesson] {
        bookmarks.reviewQueue(from: store.curriculum?.lessons ?? [], completed: store.completed)
    }

    var body: some View {
        if queue.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                Label("REVIEW QUEUE · \(queue.count)", systemImage: "bookmark.fill")
                    .font(.caption.bold()).foregroundStyle(.yellow)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(queue) { lesson in
                            ReviewQueueCard(lesson: lesson, selected: selectedID == lesson.id) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    selectedID = selectedID == lesson.id ? nil : lesson.id
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(14)
            .background(Color.yellow.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.yellow.opacity(0.18)))
        }
    }
}

private struct ReviewQueueCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var bookmarks: BookmarkStore
    let lesson: Lesson
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lesson.term).font(.headline)
                Spacer()
                BookmarkButton(lessonID: lesson.id)
            }
            Text(lesson.clue).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            if selected {
                Text(lesson.definition).font(.subheadline).lineLimit(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                NavigationLink {
                    LessonView(lesson: lesson)
                } label: {
                    Text("Study now \u{2192}").font(.caption.bold()).foregroundStyle(.mint)
                }
                LessonNoteEditor(lessonID: lesson.id)
            }
        }
        .padding(14)
        .frame(width: 220, alignment: .leading)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(selected ? 0.4 : 0.0)))
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Full Bookmarks Sheet

struct BookmarksSheet: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var bookmarks: BookmarkStore
    @Environment(\.dismiss) private var dismiss
    @State private var showDone = false

    private var pending: [Lesson] {
        bookmarks.reviewQueue(from: store.curriculum?.lessons ?? [], completed: store.completed)
    }
    private var done: [Lesson] {
        bookmarks.allBookmarked(from: store.curriculum?.lessons ?? []).filter { store.completed.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                if pending.isEmpty && done.isEmpty {
                    ContentUnavailableView("No bookmarks yet",
                        systemImage: "bookmark",
                        description: Text("Tap the bookmark icon on any lesson card to add it to your review queue."))
                } else {
                    if !pending.isEmpty {
                        Section("To review (\(pending.count))") {
                            ForEach(pending) { lesson in BookmarkRow(lesson: lesson) }
                        }
                    }
                    if !done.isEmpty {
                        Section {
                            if showDone {
                                ForEach(done) { lesson in BookmarkRow(lesson: lesson) }
                            }
                        } header: {
                            Button { withAnimation { showDone.toggle() } } label: {
                                HStack {
                                    Text("Completed (\(done.count))")
                                    Spacer()
                                    Image(systemName: showDone ? "chevron.up" : "chevron.down")
                                }
                                .font(.subheadline.bold())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct BookmarkRow: View {
    @EnvironmentObject var bookmarks: BookmarkStore
    @EnvironmentObject var store: LearningStore
    let lesson: Lesson

    var body: some View {
        NavigationLink { LessonView(lesson: lesson) } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(lesson.term).font(.headline)
                    Spacer()
                    BookmarkButton(lessonID: lesson.id)
                }
                Text(lesson.category).font(.caption).foregroundStyle(.secondary)
                if !bookmarks.note(for: lesson.id).isEmpty {
                    Text(bookmarks.note(for: lesson.id))
                        .font(.caption).foregroundStyle(.secondary).italic().lineLimit(2)
                }
            }
        }
    }
}
