import SwiftUI
import WidgetKit

// MARK: - App Group Shared Store
// Writes data to a shared App Group so the Widget Extension can read it.
// App Group ID: group.com.stacksprint.app
// The widget extension (StackSprintWidgetExtension target) reads from this same store.

enum SharedDefaults {
    static let suiteName = "group.com.stacksprint.app"
    static var store: UserDefaults { UserDefaults(suiteName: suiteName) ?? .standard }

    enum Key {
        static let streak    = "widget.streak"
        static let xp        = "widget.xp"
        static let completed = "widget.completedCount"
        static let nextTerm  = "widget.nextTerm"
        static let nextCat   = "widget.nextCategory"
    }
}

// MARK: - Widget Data Writer

@MainActor func writeWidgetData(store: LearningStore) {
    let ud = SharedDefaults.store
    ud.set(store.currentStreak,   forKey: SharedDefaults.Key.streak)
    ud.set(store.practiceXP,      forKey: SharedDefaults.Key.xp)
    ud.set(store.completed.count, forKey: SharedDefaults.Key.completed)
    if let next = store.curriculum?.lessons.first(where: { !store.completed.contains($0.id) }) {
        ud.set(next.term,     forKey: SharedDefaults.Key.nextTerm)
        ud.set(next.category, forKey: SharedDefaults.Key.nextCat)
    }
    WidgetCenter.shared.reloadAllTimelines()
}

// MARK: - Widget Extension Scaffold
// The code below is the complete implementation for the StackSprintWidgetExtension target.
// Steps to enable widgets:
//   1. Xcode → File → New Target → Widget Extension → name it "StackSprintWidgetExtension"
//   2. Add App Group "group.com.stacksprint.app" to both the main app and widget extension targets
//   3. Copy the scaffold below into the generated widget Swift file and remove the placeholder

/*
import WidgetKit
import SwiftUI

// Read shared data written by the main app
private extension UserDefaults {
    static var shared: UserDefaults { UserDefaults(suiteName: "group.com.stacksprint.app") ?? .standard }
    var widgetStreak:    Int    { integer(forKey: "widget.streak") }
    var widgetXP:        Int    { integer(forKey: "widget.xp") }
    var widgetCompleted: Int    { integer(forKey: "widget.completedCount") }
    var widgetNextTerm:  String { string(forKey: "widget.nextTerm") ?? "Start learning" }
    var widgetNextCat:   String { string(forKey: "widget.nextCategory") ?? "StackSprint" }
}

// MARK: - Streak Widget

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let xp: Int
    let completed: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streak: 7, xp: 420, completed: 18)
    }
    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let ud = UserDefaults.shared
        completion(StreakEntry(date: .now, streak: ud.widgetStreak, xp: ud.widgetXP, completed: ud.widgetCompleted))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let ud = UserDefaults.shared
        let entry = StreakEntry(date: .now, streak: ud.widgetStreak, xp: ud.widgetXP, completed: ud.widgetCompleted)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("🔥").font(.title2)
                Text("\(entry.streak)").font(.system(.title, design: .rounded, weight: .black))
                Text("day streak").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Text("\(entry.xp) XP · \(entry.completed) lessons")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(Color(.systemBackground), for: .widget)
    }
}

// MARK: - Next Lesson Lock Screen Widget

struct NextLessonEntry: TimelineEntry {
    let date: Date
    let term: String
    let category: String
}

struct NextLessonProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextLessonEntry {
        NextLessonEntry(date: .now, term: "Closures", category: "Swift")
    }
    func getSnapshot(in context: Context, completion: @escaping (NextLessonEntry) -> Void) {
        let ud = UserDefaults.shared
        completion(NextLessonEntry(date: .now, term: ud.widgetNextTerm, category: ud.widgetNextCat))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextLessonEntry>) -> Void) {
        let ud = UserDefaults.shared
        let entry = NextLessonEntry(date: .now, term: ud.widgetNextTerm, category: ud.widgetNextCat)
        let refresh = Calendar.current.date(byAdding: .hour, value: 2, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct NextLessonWidgetView: View {
    let entry: NextLessonEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Up next", systemImage: "book.fill")
                .font(.caption2.bold()).foregroundStyle(.mint)
            Text(entry.term).font(.headline.bold()).lineLimit(2)
            Text(entry.category).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(Color(.systemBackground), for: .widget)
    }
}

// MARK: - Widget Bundle

@main
struct StackSprintWidgets: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        NextLessonWidget()
    }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StreakWidget", provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("See your current streak and XP at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct NextLessonWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextLessonWidget", provider: NextLessonProvider()) { entry in
            NextLessonWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Lesson")
        .description("See your next lesson from the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}
*/
