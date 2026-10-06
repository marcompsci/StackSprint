import WidgetKit
import SwiftUI

// MARK: - Shared data key (app writes, widget reads via UserDefaults)
// Both app and widget extension must be in the same App Group:
// "group.com.stacksprint.app" — add this in Xcode → Signing & Capabilities for BOTH targets.
// Then replace UserDefaults.standard with UserDefaults(suiteName: "group.com.stacksprint.app")!

private let sharedDefaults = UserDefaults.standard   // swap to app group when configured
private let streakKey = "native.streak.widget"
private let lessonsKey = "native.lessons.widget"

// MARK: - Timeline Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let lessonsCompleted: Int
    let message: String
}

// MARK: - Provider

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7, lessonsCompleted: 23, message: "Keep it up!")
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let e = entry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [e], policy: .after(nextUpdate)))
    }

    private func entry() -> StreakEntry {
        let streak   = sharedDefaults.integer(forKey: streakKey)
        let lessons  = sharedDefaults.integer(forKey: lessonsKey)
        return StreakEntry(date: Date(), streak: streak, lessonsCompleted: lessons, message: message(streak: streak))
    }

    private func message(streak: Int) -> String {
        switch streak {
        case 0:     return "Start today!"
        case 1...2: return "Building momentum!"
        case 3...6: return "On a roll \u{1F525}"
        case 7...13: return "A full week!"
        default:    return "\(streak) days strong!"
        }
    }
}

// MARK: - Home Screen Widget View

struct StreakWidgetView: View {
    let entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:   smallView
        case .systemMedium:  mediumView
        case .accessoryCircular: circularView
        case .accessoryRectangular: rectangularView
        default: smallView
        }
    }

    // Small: streak count centered
    private var smallView: some View {
        ZStack {
            Color(red: 0.063, green: 0.133, blue: 0.220)
            VStack(spacing: 8) {
                Image(systemName: "flame.fill").font(.title).foregroundStyle(.orange)
                Text("\(entry.streak)").font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("day streak").font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
                Text(entry.message).font(.caption2).foregroundStyle(.mint).multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    // Medium: streak + lesson count side by side
    private var mediumView: some View {
        ZStack {
            Color(red: 0.063, green: 0.133, blue: 0.220)
            HStack(spacing: 0) {
                // Left: streak
                VStack(spacing: 6) {
                    Image(systemName: "flame.fill").font(.title2).foregroundStyle(.orange)
                    Text("\(entry.streak)").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("day streak").font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)

                Divider().background(.white.opacity(0.15)).padding(.vertical, 12)

                // Right: lessons + message
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill").foregroundStyle(.mint)
                        Text("\(entry.lessonsCompleted)").font(.title2.bold()).foregroundStyle(.white)
                    }
                    Text("lessons done").font(.caption).foregroundStyle(.white.opacity(0.7))
                    Spacer().frame(height: 4)
                    Text(entry.message).font(.caption.bold()).foregroundStyle(.mint)
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }

    // Lock screen circular: flame + streak number
    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "flame.fill").font(.caption).foregroundStyle(.orange)
                Text("\(entry.streak)").font(.system(.title3, design: .rounded, weight: .bold))
            }
        }
    }

    // Lock screen rectangular: streak + message
    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(entry.streak)-day streak").font(.headline)
            }
            Text(entry.message).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Configuration

@main
struct StackSprintWidget: Widget {
    let kind = "StackSprintStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(Color(red: 0.063, green: 0.133, blue: 0.220), for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Keep your StackSprint coding streak in view.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}
