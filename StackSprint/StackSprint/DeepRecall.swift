import Combine
import Foundation
import SwiftUI

// MARK: - Phases 201–230
//
// • Brain dump (free recall): write everything you remember about a track, then see
//   what you got. Free recall is one of the most effortful, and most effective, kinds
//   of retrieval practice.
// • Solid lessons (successive relearning): a lesson counts as solid after it's been
//   recalled well on three different days. Rawson & Dunlosky's work shows that
//   relearning to a criterion across sessions gives durable, long-lasting retention.
// • Week in review, a goal-gradient "next certificate" card, saved prompts, code review
//   and commit-message drills, and a "match system" appearance option.

// MARK: - Brain dump

struct BrainDumpResult: Equatable {
    let recalled: [String]
    let missed: [String]
    var percent: Int { recalled.count + missed.count == 0 ? 0 : recalled.count * 100 / (recalled.count + missed.count) }
}

enum BrainDump {
    /// Terms that appear in what the learner wrote. Matching ignores case and punctuation,
    /// and accepts a close spelling (one or two typos on longer terms).
    static func score(text: String, terms: [String]) -> BrainDumpResult {
        let words = text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        let joined = TypedAnswer.normalize(text)
        var recalled: [String] = [], missed: [String] = []
        for term in terms {
            let normalized = TypedAnswer.normalize(term)
            let termWords = term.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).count
            let hit: Bool
            if normalized.isEmpty {
                hit = false
            } else if joined.contains(normalized) {
                hit = true
            } else if termWords == 1 {
                hit = words.contains { TypedAnswer.matches($0, term) }
            } else {
                hit = false
            }
            if hit { recalled.append(term) } else { missed.append(term) }
        }
        return BrainDumpResult(recalled: recalled, missed: missed)
    }
}

@MainActor final class BrainDumpStore: ObservableObject {
    static let shared = BrainDumpStore()
    static let key = "brainDump.best"
    /// Best recall percentage per track.
    @Published private(set) var best: [String: Int] = [:]

    init(defaults: UserDefaults = .standard) {
        best = defaults.dictionary(forKey: Self.key) as? [String: Int] ?? [:]
    }

    func record(track: String, percent: Int) {
        best[track] = max(best[track] ?? 0, percent)
        persist()
    }

    func merge(_ incoming: [String: Int]) {
        for (k, v) in incoming { best[k] = max(best[k] ?? 0, v) }
        persist()
    }

    func eraseAll() { best = [:]; persist() }
    private func persist() { UserDefaults.standard.set(best, forKey: Self.key) }
}

// MARK: - Solid lessons (successive relearning)

enum Solid {
    static let daysNeeded = 3
    static let goodScore = 4

    /// Different calendar days on which the lesson's quiz scored 4/5 or better.
    static func goodDays(_ records: [LessonQuizRecord], calendar: Calendar = .current) -> Int {
        var days = Set<Date>()
        for record in records where record.total > 0 && record.score * 5 >= record.total * goodScore {
            days.insert(calendar.startOfDay(for: record.date))
        }
        return days.count
    }

    static func isSolid(_ records: [LessonQuizRecord], calendar: Calendar = .current) -> Bool {
        goodDays(records, calendar: calendar) >= daysNeeded
    }

    static func solidCount(_ records: [String: [LessonQuizRecord]], calendar: Calendar = .current) -> Int {
        records.values.filter { isSolid($0, calendar: calendar) }.count
    }
}

// MARK: - Week in review

enum WeekInReview {
    /// Lessons studied in the last 7 days, most recent first.
    static func lessonIDs(activity: Set<String>, now: Date = Date(), calendar: Calendar = .current) -> [String] {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let startKey = StreakMath.key(start, calendar)
        return TargetedDrill.recentLessonIDs(Set(activity.filter { String($0.prefix(10)) >= startKey }), limit: 20)
    }
}

// MARK: - Next certificate (goal gradient)

struct CertificateGoal: Equatable {
    let track: String
    let remaining: Int
    let total: Int
}

enum NextCertificate {
    /// The open track closest to its certificate (at least one lesson done, not yet earned).
    static func closest(lessonsByTrack: [String: [Lesson]], locked: Set<String>, completed: Set<String>,
                        best: (String) -> Int?) -> CertificateGoal? {
        lessonsByTrack.compactMap { track, lessons -> CertificateGoal? in
            guard !locked.contains(track), !lessons.isEmpty else { return nil }
            let met = TrackCertificate.progress(lessons: lessons, completed: completed, best: best)
            let started = lessons.contains { completed.contains($0.id) }
            guard started, met < lessons.count else { return nil }
            return CertificateGoal(track: track, remaining: lessons.count - met, total: lessons.count)
        }
        .sorted { $0.remaining == $1.remaining ? $0.track < $1.track : $0.remaining < $1.remaining }
        .first
    }

    static func message(_ goal: CertificateGoal) -> String {
        goal.remaining == 1
            ? "1 lesson to go for your \(goal.track) certificate."
            : "\(goal.remaining) lessons to go for your \(goal.track) certificate."
    }
}

// MARK: - Appearance

enum AppearanceMode {
    static let key = "appearance.mode"
    static let options: [(id: String, title: String, icon: String)] = [
        ("system", "Match system", "circle.lefthalf.filled"), ("light", "Light", "sun.max"), ("dark", "Dark", "moon"),
    ]

    static func scheme(_ mode: String) -> ColorScheme? {
        switch mode {
        case "light": return .light
        case "system": return nil
        default: return .dark
        }
    }
}

// MARK: - Saved prompts (AI Skills)

struct SavedPrompt: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var text: String
    let created: Date
}

@MainActor final class PromptLibrary: ObservableObject {
    static let shared = PromptLibrary()
    static let key = "prompts.saved"
    static let limit = 100
    @Published private(set) var prompts: [SavedPrompt] = []

    init(defaults: UserDefaults = .standard) {
        if let data = defaults.data(forKey: Self.key), let list = try? JSONDecoder().decode([SavedPrompt].self, from: data) {
            prompts = list
        }
    }

    /// Saves a prompt, newest first. Prompts with private details are refused.
    @discardableResult
    func save(title: String, text: String, date: Date = Date()) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, PromptCheck.privacyWarnings(trimmed).isEmpty else { return false }
        let name = title.trimmingCharacters(in: .whitespaces)
        let fallback = String(trimmed.split(separator: "\n").first ?? "").prefix(40)
        prompts.insert(SavedPrompt(id: UUID(), title: name.isEmpty ? String(fallback) : name, text: trimmed, created: date), at: 0)
        if prompts.count > Self.limit { prompts.removeLast(prompts.count - Self.limit) }
        persist()
        return true
    }

    func delete(_ id: UUID) { prompts.removeAll { $0.id == id }; persist() }

    func merge(_ incoming: [SavedPrompt]) {
        let known = Set(prompts.map(\.id))
        prompts += incoming.filter { !known.contains($0.id) }
        prompts.sort { $0.created > $1.created }
        persist()
    }

    func eraseAll() { prompts = []; persist() }
    private func persist() { UserDefaults.standard.set(try? JSONEncoder().encode(prompts), forKey: Self.key) }
}

// MARK: - Code review and commit-message drills (Professional Practice)

struct ReviewItem: Identifiable {
    let id: String
    let context: String
    let snippet: String
    let options: [String]
    let best: Int
    let why: String
}

enum CodeReviewDrills {
    static let reviews: [ReviewItem] = [
        ReviewItem(id: "cr-1", context: "A teammate's pull request adds this function.",
                   snippet: "func price(_ p: Double, _ d: Double) -> Double {\n    p - p * d\n}",
                   options: ["\"This is wrong.\"", "\"Could we name these price and discount, and add a test for 0% and 100%?\"", "\"Rewrite it my way.\""],
                   best: 1, why: "Good review comments are specific, kind and suggest a concrete next step."),
        ReviewItem(id: "cr-2", context: "The pull request changes 2,400 lines across 40 files.",
                   snippet: "+2,400 −310 lines · 40 files changed",
                   options: ["Approve it to save time", "Ask to split it into smaller pull requests", "Only read the first file"],
                   best: 1, why: "Huge changes hide bugs. Smaller pull requests get better, faster reviews."),
        ReviewItem(id: "cr-3", context: "You spot a password in the diff.",
                   snippet: "+ let dbPassword = \"Summer2026!\"",
                   options: ["Leave a comment and approve", "Block the merge, ask them to remove it and rotate the password", "Ignore it, it's only a test"],
                   best: 1, why: "A committed secret must be removed and replaced: it stays in the history even after deletion."),
        ReviewItem(id: "cr-4", context: "The code works, but you'd have used a different loop style.",
                   snippet: "for i in 0..<items.count { total += items[i].price }",
                   options: ["Request changes", "Leave an optional \"nit:\" suggestion and approve", "Say nothing ever"],
                   best: 1, why: "Separate must-fix issues from preferences. Label small style ideas as optional."),
        ReviewItem(id: "cr-5", context: "A new function has no tests.",
                   snippet: "+ func isValidEmail(_ s: String) -> Bool { … }",
                   options: ["\"Tests?\"", "\"Could you add tests for a valid address, a missing @ and an empty string?\"", "Write the tests yourself without telling them"],
                   best: 1, why: "Name the cases you'd like covered so the author knows exactly what to add."),
        ReviewItem(id: "cr-6", context: "You don't understand why a change was made.",
                   snippet: "- timeout = 30\n+ timeout = 300",
                   options: ["\"Why?\"", "\"What's the reason for 300? A comment in the code would help future readers too.\"", "Approve and hope"],
                   best: 1, why: "Asking for the reason, and suggesting it's written down, helps everyone who reads the code later."),
    ]

    static let commits: [ReviewItem] = [
        ReviewItem(id: "cm-1", context: "You fixed a crash when the cart is empty.", snippet: "",
                   options: ["fix stuff", "Fix crash when checking out with an empty cart", "changes"],
                   best: 1, why: "A good message says what changed and why, in a short imperative sentence."),
        ReviewItem(id: "cm-2", context: "You added a dark mode toggle to Settings.", snippet: "",
                   options: ["Add dark mode toggle to Settings", "Added a toggle for dark mode to the settings screen today after lunch", "update"],
                   best: 0, why: "Short, specific and in the imperative (\"Add\", \"Fix\"), like an instruction to the codebase."),
        ReviewItem(id: "cm-3", context: "One commit renames a file, fixes a bug and updates the README.", snippet: "",
                   options: ["One commit: \"Various changes\"", "Three commits, one per change", "Don't commit, just push"],
                   best: 1, why: "One change per commit makes history easy to read, review and undo."),
        ReviewItem(id: "cm-4", context: "You updated a library to patch a security issue.", snippet: "",
                   options: ["bump", "Update lodash to 4.17.21 to fix prototype pollution (CVE-2021-23337)", "security"],
                   best: 1, why: "Say which dependency, which version, and why. Future readers will need the reason."),
        ReviewItem(id: "cm-5", context: "You're committing a work-in-progress before lunch on your own branch.", snippet: "",
                   options: ["WIP: login form layout (validation not done)", "done", "asdf"],
                   best: 0, why: "Even temporary commits should say what's there and what isn't, so you (or others) can pick it up."),
        ReviewItem(id: "cm-6", context: "You reverted yesterday's change because it broke sign-in.", snippet: "",
                   options: ["oops", "Revert \"Change session timeout\": it signed users out on launch", "fix"],
                   best: 1, why: "Say what's being reverted and why, so nobody re-applies the broken change."),
    ]
}
