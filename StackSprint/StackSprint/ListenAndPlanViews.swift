import SwiftUI

// MARK: - How hard was it? (lesson)

struct LessonFeelPicker: View {
    let lesson: Lesson
    @ObservedObject private var feels = LessonFeelStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How did this one feel?").font(.headline)
            HStack(spacing: 10) {
                ForEach(LessonFeel.allCases) { feel in
                    let chosen = feels.ratings[lesson.id] == feel
                    Button {
                        feels.rate(lesson.id, feel)
                        HapticManager.shared.selection()
                    } label: {
                        Label(feel.label, systemImage: feel.icon)
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(chosen ? Color.mint.opacity(0.2) : SprintPalette.card,
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(chosen ? Color.mint : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(chosen ? .isSelected : [])
                }
            }
            if feels.ratings[lesson.id] == .hard {
                Text("Got it. This lesson will come back tomorrow, and first in your reviews.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Listen & recall

struct ListenRecallView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var reviews = SM2Engine.shared
    @AppStorage("listen.count") private var listened = 0
    @State private var cards: [ListenCard] = []
    @State private var index = 0
    @State private var revealed = false
    @State private var playing = false
    @State private var task: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 22) {
            if cards.isEmpty {
                ContentUnavailableView("Finish a few lessons first", systemImage: "headphones",
                                       description: Text("Listen & recall reviews lessons you've already finished."))
            } else if cards.indices.contains(index) {
                Text("\(index + 1) of \(cards.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
                Image(systemName: revealed ? "checkmark.bubble.fill" : "ear.fill")
                    .font(.system(size: 56)).foregroundStyle(.mint)
                    .symbolEffect(.pulse, isActive: playing && !revealed)
                Text(cards[index].prompt).font(.title3).multilineTextAlignment(.center)
                if revealed {
                    Text(cards[index].answer).font(.headline).multilineTextAlignment(.center).foregroundStyle(.mint)
                } else {
                    Text("Answer in your head…").foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                    Button(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill") {
                        playing ? stop() : play()
                    }
                    .buttonStyle(.borderedProminent).tint(.mint)
                    Button("Skip", systemImage: "forward.fill") { advance() }.buttonStyle(.bordered)
                }
            } else {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(.green)
                Text("Done: \(cards.count) lessons reviewed by ear.").font(.title3.bold())
                Button("Start again") { index = 0; revealed = false; play() }.buttonStyle(.borderedProminent)
            }
            Text("Good for walks and commutes. Saying the answer before you hear it is what makes it work.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: 600)
        .navigationTitle("Listen & recall")
        .modifier(SprintTheme())
        .onAppear { if cards.isEmpty { cards = build() } }
        .onDisappear { stop() }
    }

    private func build() -> [ListenCard] {
        let lessons = (store.curriculum?.lessons ?? []).filter { store.completed.contains($0.id) && !premiumStore.isLocked($0.category) }
        let candidates = lessons.map { (lesson: $0, recall: reviews.card(for: $0.id).map { MemoryModel.recall(card: $0) } ?? 0.5) }
        return ListenRecall.queue(MixedReview.weighted(candidates, hard: LessonFeelStore.shared.hardLessons))
    }

    private func play() {
        guard cards.indices.contains(index) else { return }
        playing = true
        task?.cancel()
        task = Task { @MainActor in
            while !Task.isCancelled && cards.indices.contains(index) {
                revealed = false
                VoiceManager.shared.speak(cards[index].prompt)
                try? await Task.sleep(for: .seconds(Double(ListenRecall.pauseSeconds) + Double(cards[index].prompt.count) / 14))
                if Task.isCancelled { break }
                revealed = true
                VoiceManager.shared.speak(cards[index].answer)
                listened += 1
                try? await Task.sleep(for: .seconds(2 + Double(cards[index].answer.count) / 14))
                if Task.isCancelled { break }
                index += 1
            }
            playing = false
            if !cards.indices.contains(index) { store.recordPractice() }
        }
    }

    private func stop() {
        task?.cancel()
        task = nil
        playing = false
        VoiceManager.shared.stop()
    }

    private func advance() {
        let wasPlaying = playing
        stop()
        revealed = false
        index += 1
        if wasPlaying { play() }
    }
}

// MARK: - Your first week (Learn)

struct FirstWeekCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var notifications: NotificationManager
    @ObservedObject private var mastery = MasteryStore.shared
    @ObservedObject private var explanations = ExplainBackStore.shared
    @ObservedObject private var dumps = BrainDumpStore.shared
    @AppStorage(FirstWeek.startKey) private var start: Double = 0
    @AppStorage(FirstWeek.hiddenKey) private var hidden = false
    @AppStorage(ArcadeKeys.predictBest) private var predictBest = 0
    @AppStorage(SpeedRound.bestKey) private var speedBest = 0

    var body: some View {
        let state = FirstWeekState(lessonsDone: store.completed.count, quizzesTaken: mastery.records.count,
                                   remindersOn: notifications.enabled && notifications.permissionGranted, explanations: explanations.notes.count,
                                   arcadePlayed: predictBest > 0 || speedBest > 0, brainDumps: dumps.best.count,
                                   streak: store.currentStreak)
        let tasks = FirstWeek.tasks(state)
        Group {
            if FirstWeek.isVisible(start: start > 0 ? Date(timeIntervalSince1970: start) : nil, tasks: tasks, hidden: hidden) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Your first week", systemImage: "map.fill").font(.headline)
                        Spacer()
                        Text("\(tasks.filter(\.done).count) of \(tasks.count)").font(.caption.bold().monospacedDigit())
                            .foregroundStyle(.secondary)
                        Button { hidden = true } label: { Image(systemName: "xmark") }
                            .buttonStyle(.borderless).accessibilityLabel("Hide first week checklist")
                    }
                    ProgressView(value: Double(tasks.filter(\.done).count), total: Double(tasks.count)).tint(.mint)
                    ForEach(tasks) { task in
                        Label(task.title, systemImage: task.done ? "checkmark.circle.fill" : "circle")
                            .font(.subheadline)
                            .foregroundStyle(task.done ? Color.secondary : Color.primary)
                            .strikethrough(task.done)
                            .accessibilityValue(task.done ? "Done" : "Not done")
                    }
                    Text("The first days are when habits form. These are the ones that help most.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .onAppear { if start == 0 { start = Date().timeIntervalSince1970 } }
        .onChange(of: store.completed.count + mastery.records.count + explanations.notes.count + dumps.best.count + store.currentStreak) { _, _ in
            markCompleteIfDone()
        }
    }

    private func markCompleteIfDone() {
        let state = FirstWeekState(lessonsDone: store.completed.count, quizzesTaken: mastery.records.count,
                                   remindersOn: notifications.enabled && notifications.permissionGranted,
                                   explanations: explanations.notes.count, arcadePlayed: predictBest > 0 || speedBest > 0,
                                   brainDumps: dumps.best.count, streak: store.currentStreak)
        if FirstWeek.tasks(state).allSatisfy(\.done) { UserDefaults.standard.set(true, forKey: FirstWeek.completedKey) }
    }
}

// MARK: - Best study time (memory)

struct BestStudyTimeCard: View {
    @ObservedObject private var mastery = MasteryStore.shared

    var body: some View {
        if let best = BestStudyTime.find(records: mastery.records) {
            VStack(alignment: .leading, spacing: 4) {
                Label("You do best in the \(best.time.label)", systemImage: "clock.fill").font(.headline).foregroundStyle(.indigo)
                Text("\(best.accuracy)% of quiz answers right, against \(best.otherAccuracy)% at other times. Try scheduling your reminder then.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
