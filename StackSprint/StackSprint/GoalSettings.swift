import SwiftUI

// MARK: - Goal Model

struct LearningGoal {
    let lessonsPerWeek: Int

    var label: String {
        switch lessonsPerWeek {
        case 1:  return "Casual — 1 lesson/week"
        case 3:  return "Steady — 3 lessons/week"
        case 5:  return "Committed — 5 lessons/week"
        case 10: return "Intensive — 10 lessons/week"
        default: return "\(lessonsPerWeek) lessons/week"
        }
    }

    var emoji: String {
        switch lessonsPerWeek {
        case 1:  return "\u{1F331}"
        case 3:  return "\u{1F4AA}"
        case 5:  return "\u{1F525}"
        case 10: return "\u{1F680}"
        default: return "\u{2B50}"
        }
    }

    static let presets: [LearningGoal] = [
        LearningGoal(lessonsPerWeek: 1),
        LearningGoal(lessonsPerWeek: 3),
        LearningGoal(lessonsPerWeek: 5),
        LearningGoal(lessonsPerWeek: 10),
    ]
}

// MARK: - Goal Progress View (embed in LearnView hero)

struct GoalProgressBanner: View {
    @EnvironmentObject var store: LearningStore
    @AppStorage("goal.weeklyLessons") private var weeklyGoal = 3

    private var lessonsThisWeek: Int {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) else { return 0 }
        let thisWeekKeys = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }.map { date -> String in
            let c = calendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        }
        return store.practicedDays.filter { thisWeekKeys.contains($0) }.count
    }

    var body: some View {
        let done = lessonsThisWeek
        let goal = weeklyGoal
        let pct  = min(Double(done) / Double(max(goal, 1)), 1.0)
        let met  = done >= goal

        HStack(spacing: 12) {
            Text(met ? "\u{1F3C6}" : LearningGoal(lessonsPerWeek: goal).emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(met ? "Weekly goal met!" : "Weekly goal")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(done) / \(goal) days")
                        .font(.caption.bold().monospaced())
                        .foregroundStyle(met ? .mint : .secondary)
                }
                ProgressView(value: pct)
                    .tint(met ? .mint : .orange)
                    .animation(.easeOut(duration: 0.4), value: pct)
            }
        }
        .padding(14)
        .background(met ? Color.mint.opacity(0.08) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(met ? Color.mint.opacity(0.3) : Color.secondary.opacity(0.12)))
    }
}

// MARK: - Goal Settings Section (embed in AccountView)

struct GoalSettingsSection: View {
    @AppStorage("goal.weeklyLessons") private var weeklyGoal = 3

    var body: some View {
        Section {
            ForEach(LearningGoal.presets, id: \.lessonsPerWeek) { goal in
                Button {
                    withAnimation { weeklyGoal = goal.lessonsPerWeek }
                } label: {
                    HStack {
                        Text(goal.emoji)
                        Text(goal.label).foregroundStyle(.primary)
                        Spacer()
                        if weeklyGoal == goal.lessonsPerWeek {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Weekly learning goal")
        } footer: {
            Text("Tracks how many days per week you practice — not lesson count. A practice day counts when you complete at least one lesson or recall card.")
        }
    }
}

// MARK: - Onboarding Goal Step (used in WelcomeAdventure)

struct OnboardingGoalStep: View {
    var onComplete: () -> Void
    @AppStorage("goal.weeklyLessons") private var weeklyGoal = 3
    @AppStorage("goal.startingTrack") var startingTrack = "Web development"

    private let tracks: [(name: String, icon: String, desc: String)] = [
        ("Web development", "globe",          "HTML, CSS, JavaScript — build things for browsers"),
        ("Python",          "ladybug.fill",   "The easiest first language — scripts, data, AI"),
        ("Cybersecurity",   "lock.shield.fill","Protect systems and understand how attacks work"),
        ("TypeScript",      "t.square.fill",  "JavaScript with types — industry standard"),
        ("React",           "atom",           "Build interactive UIs used by millions of apps"),
        ("Swift",           "swift",          "Build iOS and Mac apps with Apple's language"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ALMOST THERE").font(.caption.bold()).tracking(1.3).foregroundStyle(.mint)
                Text("Set your goal").font(.system(.title, design: .rounded, weight: .bold))
                Text("Pick a pace that fits your life, then choose where to start.").font(.subheadline).foregroundStyle(.secondary)
            }

            // Pace picker
            VStack(alignment: .leading, spacing: 10) {
                Text("HOW OFTEN?").font(.caption.bold()).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(LearningGoal.presets, id: \.lessonsPerWeek) { goal in
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) { weeklyGoal = goal.lessonsPerWeek }
                        } label: {
                            VStack(spacing: 4) {
                                Text(goal.emoji).font(.title2)
                                Text("\(goal.lessonsPerWeek)x").font(.headline)
                                Text("week").font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(weeklyGoal == goal.lessonsPerWeek ? Color.mint.opacity(0.15) : SprintPalette.card,
                                        in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(weeklyGoal == goal.lessonsPerWeek ? Color.mint : Color.secondary.opacity(0.2)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Track picker
            VStack(alignment: .leading, spacing: 10) {
                Text("WHERE TO START?").font(.caption.bold()).foregroundStyle(.secondary)
                ForEach(tracks, id: \.name) { track in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { startingTrack = track.name }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: track.icon)
                                .frame(width: 26)
                                .foregroundStyle(startingTrack == track.name ? .mint : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.name).font(.subheadline.bold())
                                Text(track.desc).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if startingTrack == track.name {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint)
                            }
                        }
                        .padding(12)
                        .background(startingTrack == track.name ? Color.mint.opacity(0.08) : SprintPalette.card,
                                    in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(startingTrack == track.name ? Color.mint.opacity(0.4) : Color.secondary.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(action: onComplete) {
                Text("Let\u{2019}s go \u{2192}")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent).tint(.mint)
        }
        .padding(.horizontal, 4)
    }
}
