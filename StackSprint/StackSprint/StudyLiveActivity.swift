import ActivityKit
import Combine
import SwiftUI

// MARK: - Live Activity Attributes

struct StudyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var lessonTitle: String
        var category: String
        var elapsedSeconds: Int
        var isComplete: Bool

        var elapsedFormatted: String {
            let m = elapsedSeconds / 60
            let s = elapsedSeconds % 60
            return String(format: "%d:%02d", m, s)
        }
    }
    var lessonID: String
    var categoryColor: String  // hex string for tinting
}

// MARK: - Study Activity Manager

@MainActor final class StudyActivityManager: ObservableObject {
    static let shared = StudyActivityManager()

    @Published var isActive = false
    @Published var elapsedSeconds = 0

    private var currentActivity: Activity<StudyActivityAttributes>?
    private var timerTask: Task<Void, Never>?
    private var currentLesson: Lesson?

    private init() {}

    func start(lesson: Lesson) async {
        guard #available(iOS 16.1, *) else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !isActive else { return }

        let attrs = StudyActivityAttributes(
            lessonID: lesson.id,
            categoryColor: categoryHex(lesson.category)
        )
        let state = StudyActivityAttributes.ContentState(
            lessonTitle: lesson.term,
            category: lesson.category,
            elapsedSeconds: 0,
            isComplete: false
        )
        do {
            let activity = try Activity.request(
                attributes: attrs,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            currentLesson = lesson
            isActive = true
            elapsedSeconds = 0
            startTimer()
        } catch { }
    }

    func complete() async {
        guard #available(iOS 16.1, *) else { return }
        stopTimer()
        guard let lesson = currentLesson else { return }
        let final = StudyActivityAttributes.ContentState(
            lessonTitle: lesson.term,
            category: lesson.category,
            elapsedSeconds: elapsedSeconds,
            isComplete: true
        )
        let dismissAt = Date.now.addingTimeInterval(8)
        await currentActivity?.end(
            .init(state: final, staleDate: nil),
            dismissalPolicy: .after(dismissAt)
        )
        reset()
    }

    func cancel() async {
        guard #available(iOS 16.1, *) else { return }
        stopTimer()
        guard let lesson = currentLesson else { return }
        let state = StudyActivityAttributes.ContentState(
            lessonTitle: lesson.term,
            category: lesson.category,
            elapsedSeconds: elapsedSeconds,
            isComplete: false
        )
        await currentActivity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        reset()
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { break }
                self.elapsedSeconds += 1
                guard #available(iOS 16.1, *) else { continue }
                guard let lesson = self.currentLesson else { continue }
                let state = StudyActivityAttributes.ContentState(
                    lessonTitle: lesson.term,
                    category: lesson.category,
                    elapsedSeconds: self.elapsedSeconds,
                    isComplete: false
                )
                await self.currentActivity?.update(.init(state: state, staleDate: nil))
            }
        }
    }

    private func stopTimer() { timerTask?.cancel(); timerTask = nil }

    private func reset() {
        currentActivity = nil
        currentLesson = nil
        isActive = false
        elapsedSeconds = 0
    }

    private func categoryHex(_ category: String) -> String {
        switch category {
        case "Python":        return "#F97316"
        case "Cybersecurity": return "#A855F7"
        case "Go":            return "#14B8A6"
        case "Rust":          return "#CC5914"
        case "Interview Prep":return "#3B82F6"
        default:              return "#22D3EE"
        }
    }
}

// MARK: - Live Activity View Modifier (attach to LessonView)

struct StudyLiveActivityModifier: ViewModifier {
    let lesson: Lesson
    @EnvironmentObject var store: LearningStore

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { await StudyActivityManager.shared.start(lesson: lesson) }
            }
            .onDisappear {
                Task { await StudyActivityManager.shared.cancel() }
            }
            .onChange(of: store.completed) { _, completed in
                if completed.contains(lesson.id) {
                    Task { await StudyActivityManager.shared.complete() }
                }
            }
    }
}

extension View {
    func trackedWithLiveActivity(lesson: Lesson) -> some View {
        modifier(StudyLiveActivityModifier(lesson: lesson))
    }
}

// MARK: - Widget Extension Scaffold (add to StackSprintWidgetExtension target)
// Add this Live Activity view to the widget extension alongside the existing widgets.

/*
import ActivityKit
import SwiftUI
import WidgetKit

// NOTE: Copy StudyActivityAttributes to the widget extension target or use a shared Swift Package.

struct StudyTimerLiveActivityView: View {
    let context: ActivityViewContext<StudyActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Label(context.state.category, systemImage: "book.fill")
                    .font(.caption2.bold()).foregroundStyle(.secondary)
                Text(context.state.lessonTitle)
                    .font(.headline.bold()).lineLimit(1)
            }
            Spacer()
            if context.state.isComplete {
                Label("Done!", systemImage: "checkmark.circle.fill")
                    .font(.headline.bold()).foregroundStyle(.mint)
            } else {
                VStack(spacing: 2) {
                    Text(context.state.elapsedFormatted)
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                    Text("studying").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
    }
}

// Register in the widget bundle:
// struct StudyTimerLiveActivity: Widget {
//     var body: some WidgetConfiguration {
//         ActivityConfiguration(for: StudyActivityAttributes.self) { context in
//             StudyTimerLiveActivityView(context: context)
//         } dynamicIsland: { context in
//             DynamicIsland {
//                 DynamicIslandExpandedRegion(.leading) {
//                     Label(context.state.category, systemImage: "book.fill").font(.caption)
//                 }
//                 DynamicIslandExpandedRegion(.trailing) {
//                     Text(context.state.elapsedFormatted)
//                         .font(.system(.body, design: .monospaced, weight: .bold))
//                 }
//                 DynamicIslandExpandedRegion(.bottom) {
//                     Text(context.state.lessonTitle).font(.headline).lineLimit(1)
//                 }
//             } compactLeading: {
//                 Image(systemName: "book.fill").foregroundStyle(.mint)
//             } compactTrailing: {
//                 Text(context.state.elapsedFormatted)
//                     .font(.system(.caption, design: .monospaced, weight: .bold))
//             } minimal: {
//                 Image(systemName: "book.fill")
//             }
//         }
//     }
// }
*/
