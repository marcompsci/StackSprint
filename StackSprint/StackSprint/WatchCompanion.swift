import SwiftUI

// MARK: - Watch Data Bridge (iOS Side)
// Writes watch-ready structured data to the shared App Group.
// The watchOS extension reads from the same "group.com.stacksprint.app" UserDefaults suite.
//
// To add the Watch companion:
//   1. Xcode → File → New Target → Watch App (SwiftUI lifecycle)
//   2. Name it "StackSprintWatch"; enable "Include Notification Scene"
//   3. In Signing & Capabilities, add App Group "group.com.stacksprint.app" to BOTH targets
//   4. Add WatchCompanion.swift to the Watch extension target (it compiles on both platforms)
//   5. The watchOS app entry point and main views are defined below inside #if os(watchOS)

extension SharedDefaults.Key {
    // Watch-specific keys (written by iOS, read by watchOS extension)
    static let watchDueCount       = "watch.dueCount"
    static let watchDueLessonTerm  = "watch.dueLessonTerm"
    static let watchDueLessonCat   = "watch.dueLessonCategory"
    static let watchLastPracticed  = "watch.lastPracticed"
    static let watchStreak         = "watch.streak"
    static let watchXP             = "watch.xp"
    static let watchTodayDone      = "watch.todayDone"
}

@MainActor func writeWatchData(store: LearningStore) {
    let ud = SharedDefaults.store
    let dueCards = SM2Engine.shared.dueCards(in: store.curriculum?.lessons ?? [])
    ud.set(dueCards.count, forKey: SharedDefaults.Key.watchDueCount)
    ud.set(store.currentStreak, forKey: SharedDefaults.Key.watchStreak)
    ud.set(store.practiceXP, forKey: SharedDefaults.Key.watchXP)
    if let first = dueCards.first {
        ud.set(first.term, forKey: SharedDefaults.Key.watchDueLessonTerm)
        ud.set(first.category, forKey: SharedDefaults.Key.watchDueLessonCat)
    }
    let todayKey = ISO8601DateFormatter.localDate(Date())
    ud.set(store.practicedDays.contains(todayKey), forKey: SharedDefaults.Key.watchTodayDone)
    ud.synchronize()
}

private extension ISO8601DateFormatter {
    static func localDate(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.string(from: date)
    }
}

// MARK: - watchOS Companion App
// All code below only compiles in the watchOS target. Add this file to the Watch App extension.

#if os(watchOS)
import WatchKit
import WidgetKit

@main
struct StackSprintWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}

// MARK: Watch Root View

struct WatchRootView: View {
    @State private var dueCount       = 0
    @State private var dueTerm        = "No lessons due"
    @State private var dueCategory    = ""
    @State private var streak         = 0
    @State private var xp             = 0
    @State private var todayDone      = false

    private var ud: UserDefaults { UserDefaults(suiteName: "group.com.stacksprint.app") ?? .standard }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Streak ring
                WatchStreakRing(streak: streak, todayDone: todayDone)

                // Due lesson card
                if dueCount > 0 {
                    WatchDueLessonCard(term: dueTerm, category: dueCategory, dueCount: dueCount)
                } else {
                    WatchDoneForDay()
                }

                // XP stat
                HStack {
                    Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                    Text("\(xp) XP").font(.caption.bold())
                }
                .padding(8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding()
        }
        .onAppear { loadData() }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
            loadData()
        }
    }

    private func loadData() {
        dueCount   = ud.integer(forKey: "watch.dueCount")
        dueTerm    = ud.string(forKey: "watch.dueLessonTerm") ?? "Start learning"
        dueCategory = ud.string(forKey: "watch.dueLessonCategory") ?? "StackSprint"
        streak     = ud.integer(forKey: "watch.streak")
        xp         = ud.integer(forKey: "watch.xp")
        todayDone  = ud.bool(forKey: "watch.todayDone")
    }
}

// MARK: Watch Streak Ring

struct WatchStreakRing: View {
    let streak: Int
    let todayDone: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: todayDone ? 1 : 0.85)
                .stroke(todayDone ? Color.mint : Color.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(streak)").font(.system(size: 22, weight: .bold, design: .rounded))
                Text("🔥").font(.caption2)
            }
        }
        .frame(width: 70, height: 70)
    }
}

// MARK: Watch Due Lesson Card

struct WatchDueLessonCard: View {
    let term: String
    let category: String
    let dueCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                Spacer()
                Text("\(dueCount) due").font(.system(size: 9)).foregroundStyle(.orange)
            }
            Text(term).font(.system(size: 14, weight: .bold)).lineLimit(2)
            Text("Open app to practice").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: Watch Done For Day

struct WatchDoneForDay: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(.mint)
            Text("All caught up!").font(.system(size: 13, weight: .semibold))
            Text("Come back tomorrow").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

#endif
