import Charts
import SwiftUI

// MARK: - Answer review (after any quiz)

struct AnswerReviewList: View {
    let answers: [QuizAnswer]
    @State private var expanded = false

    var body: some View {
        if !answers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.smooth(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack {
                        Label("Review all answers", systemImage: "list.bullet.clipboard").font(.headline)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                if expanded {
                    ForEach(Array(answers.enumerated()), id: \.offset) { index, answer in
                        row(index, answer)
                    }
                }
            }
        }
    }

    private func row(_ index: Int, _ answer: QuizAnswer) -> some View {
        let q = answer.question
        let yours = q.choices.indices.contains(answer.chosen) ? q.choices[answer.chosen] : "A typed answer that didn't match"
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: answer.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(answer.correct ? Color.green : Color.red)
                Text("\(index + 1). \(q.prompt)").font(.subheadline.bold()).fixedSize(horizontal: false, vertical: true)
            }
            if !answer.correct {
                Text("You said: \(yours)").font(.caption).foregroundStyle(.secondary)
            }
            Text("Answer: \(q.choices[q.answer])").font(.caption)
            if let confidence = answer.confidence {
                Text(confidence == .sure ? "You were sure" : "You were guessing").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Placement check

/// "Already know some of this?" Test out of the first lessons of a track.
struct PlacementCheckView: View {
    let track: String
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var placement = PlacementStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [LessonQuizQuestion] = []
    @State private var showingQuiz = false
    @State private var result: [String]?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let result {
                        Text(result.isEmpty ? "Let's start from the beginning" : "You already know \(result.count) \(result.count == 1 ? "lesson" : "lessons")")
                            .font(.title2.bold())
                        Text(result.isEmpty
                             ? "No problem: the first lessons are short, and you'll move fast."
                             : "Continue will skip them. They'll still come up for a quick review in a few days, to make sure they stick. They don't count as finished and earn no XP.")
                            .foregroundStyle(.secondary)
                        Button("Done") { dismiss() }.buttonStyle(.borderedProminent).tint(.mint)
                    } else {
                        Text("Already know some \(track)?").font(.title2.bold())
                        Text("Answer \(questions.count) quick questions about the first lessons. Anything you get right *and* mark as Sure is skipped. Guesses don't count.")
                            .foregroundStyle(.secondary)
                        Button {
                            showingQuiz = true
                        } label: {
                            Label("Start the check", systemImage: "checklist").font(.headline)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent).tint(.mint)
                        .disabled(questions.isEmpty)
                    }
                }
                .padding(24).frame(maxWidth: 700)
            }
            .navigationTitle("Placement check")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onAppear {
                let trackLessons = store.lessonsByTrack[track] ?? []
                let lessons = Placement.candidates(track: trackLessons, completed: store.completed, known: placement.known)
                questions = Placement.questions(for: lessons, track: trackLessons)
            }
            .sheet(isPresented: $showingQuiz) {
                LessonQuizView(lesson: nil, questions: questions, title: "Placement check") { quiz in
                    let known = Placement.knownLessons(from: quiz.answers)
                    placement.markKnown(known)
                    // Bring each one back for a review in a few days, to confirm it.
                    for id in known { SM2Engine.shared.recordReview(lessonID: id, quality: 4) }
                    result = known
                }
            }
        }
    }
}

/// Shown on Learn to newer learners.
struct PlacementPromptCard: View {
    @EnvironmentObject var store: LearningStore
    @AppStorage("goal.startingTrack") private var startingTrack = "Web development"
    @ObservedObject private var placement = PlacementStore.shared
    @State private var showing = false

    var body: some View {
        if store.completed.count < 3 && placement.known.isEmpty && !(store.lessonsByTrack[startingTrack] ?? []).isEmpty {
            Button { showing = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "forward.end.circle.fill").font(.title).foregroundStyle(.mint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Already know some \(startingTrack)?").font(.headline)
                        Text("Take a short check and skip what you know.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showing) { PlacementCheckView(track: startingTrack) }
        }
    }
}

// MARK: - Two-minute review (Learn, on days you haven't practised)

struct QuickReviewCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var questions: [LessonQuizQuestion] = []
    @State private var showing = false

    var body: some View {
        if !store.practicedToday && store.completed.count >= 2 {
            Button {
                questions = build()
                showing = !questions.isEmpty
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "timer").font(.title).foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Short on time?").font(.headline)
                        Text("A 3-question review keeps your streak and your memory going.")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showing) {
                LessonQuizView(lesson: nil, questions: questions, title: "Two-minute review") { result in
                    for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                    store.recordPractice()
                }
            }
        }
    }

    private func build() -> [LessonQuizQuestion] {
        QuickReviewBuilder.questions(store: store, locked: premiumStore.lockedTracks)
    }
}

enum QuickReviewBuilder {
    static func questions(store: LearningStore, locked: Set<String>) -> [LessonQuizQuestion] {
        let all = store.curriculum?.lessons ?? []
        let open = all.filter { !locked.contains($0.category) }
        let due = SM2Engine.shared.dueCards(in: open)
        let byID = Dictionary(open.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let recent = TargetedDrill.recentLessonIDs(store.lessonActivity).compactMap { byID[$0] }
        let finished = open.filter { store.completed.contains($0.id) }
        return TargetedDrill.quickReview(due: due, recent: recent.isEmpty ? Array(finished.suffix(3).reversed()) : recent, all: all)
    }
}

// MARK: - My terms (a personal glossary)

struct MyTermsView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @EnvironmentObject var bookmarks: BookmarkStore
    @ObservedObject private var reviews = SM2Engine.shared
    @ObservedObject private var explanations = ExplainBackStore.shared
    @State private var query = ""
    @State private var track: String?
    @State private var onlyLearned = true

    private var lessons: [Lesson] {
        (store.curriculum?.lessons ?? []).filter {
            !premiumStore.isLocked($0.category) && (!onlyLearned || store.completed.contains($0.id))
        }
    }

    var body: some View {
        let entries = Glossary.entries(lessons, query: query, track: track)
        List {
            Section {
                Toggle("Only lessons I've finished", isOn: $onlyLearned)
                Picker("Track", selection: $track) {
                    Text("All tracks").tag(String?.none)
                    ForEach(store.tracks.filter { !premiumStore.isLocked($0) }, id: \.self) { Text($0).tag(Optional($0)) }
                }
            }
            if entries.isEmpty {
                ContentUnavailableView(onlyLearned && query.isEmpty ? "Finish a lesson to start your glossary" : "No matches",
                                       systemImage: "character.book.closed")
            }
            ForEach(Glossary.sections(entries), id: \.letter) { section in
                Section(section.letter) {
                    ForEach(section.lessons) { lesson in
                        NavigationLink { LessonView(lesson: lesson) } label: { row(lesson) }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search terms and definitions")
        .navigationTitle("My terms")
        .modifier(SprintTheme())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: notesMarkdown, preview: SharePreview("My StackSprint notes")) {
                    Label("Export my notes", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var notesMarkdown: String {
        StudyNotesExport.markdown(lessons: store.curriculum?.lessons ?? [], notes: bookmarks.notes,
                                  explanations: explanations.notes)
    }

    private func row(_ lesson: Lesson) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Circle().fill(dot(lesson)).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.term).font(.subheadline.bold())
                Text(LessonQuizBuilder.firstSentence(lesson.definition)).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func dot(_ lesson: Lesson) -> Color {
        guard let card = reviews.card(for: lesson.id) else { return .secondary.opacity(0.4) }
        switch MemoryModel.band(MemoryModel.recall(card: card)) {
        case .strong: return .green
        case .okay: return .mint
        case .fading: return .orange
        }
    }
}

// MARK: - Lesson history (from Memory)

struct LessonHistoryView: View {
    let lesson: Lesson
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var mastery = MasteryStore.shared
    @ObservedObject private var reviews = SM2Engine.shared
    @ObservedObject private var explanations = ExplainBackStore.shared
    @State private var retaking = false

    var body: some View {
        let records = mastery.records[lesson.id] ?? []
        List {
            Section {
                LabeledContent("Status", value: mastery.level(lesson.id).rawValue.capitalized)
                if let card = reviews.card(for: lesson.id) {
                    LabeledContent("Recall now", value: "\(Int((MemoryModel.recall(card: card) * 100).rounded()))%")
                    LabeledContent("Next review", value: card.dueDate.formatted(date: .abbreviated, time: .omitted))
                }
                if let best = mastery.best(lesson.id) { LabeledContent("Best quiz", value: "\(best) of 5") }
            }
            if records.count >= 2 {
                Section("Quiz scores") {
                    Chart(Array(records.enumerated()), id: \.offset) { index, record in
                        LineMark(x: .value("Attempt", index + 1), y: .value("Score", record.score))
                        PointMark(x: .value("Attempt", index + 1), y: .value("Score", record.score))
                    }
                    .chartYScale(domain: 0...5)
                    .frame(height: 140)
                    .foregroundStyle(.mint)
                    .accessibilityLabel("Quiz scores: \(records.map { "\($0.score)" }.joined(separator: ", "))")
                }
            }
            if !records.isEmpty {
                Section("Attempts") {
                    ForEach(Array(records.enumerated().reversed()), id: \.offset) { _, record in
                        HStack {
                            Text(record.date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline)
                            Spacer()
                            if (record.confidentMisses ?? 0) > 0 {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                    .accessibilityLabel("Had a confident mistake")
                            }
                            Text("\(record.score)/\(record.total)").font(.subheadline.monospacedDigit().bold())
                        }
                    }
                }
            }
            if let mine = explanations.notes[lesson.id] {
                Section("In your words") { Text(mine).font(.subheadline) }
            }
            Section {
                Button("Retake the lesson quiz", systemImage: "arrow.clockwise") { retaking = true }
                NavigationLink("Open the lesson") { LessonView(lesson: lesson) }
            }
        }
        .navigationTitle(lesson.term)
        .modifier(SprintTheme())
        .sheet(isPresented: $retaking) {
            let base = LessonQuizBuilder.build(for: lesson, in: store.lessonsByTrack[lesson.category] ?? [])
            LessonQuizView(lesson: lesson, questions: Retest.reshuffled(base, seed: "retake|\(lesson.id)|\(Date().timeIntervalSince1970)"),
                           title: "Retake") { result in
                LessonQuizRecorder.record(lesson.id, result)
                for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                store.recordPractice()
            }
        }
    }
}

// MARK: - Memory extras: calibration, confident mistakes, weak-type drill

struct MemoryInsightsSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var mastery = MasteryStore.shared
    @State private var drill: [LessonQuizQuestion] = []
    @State private var drillTitle = ""
    @State private var showingDrill = false

    var body: some View {
        let lessons = store.curriculum?.lessons ?? []
        let byID = Dictionary(lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let confident = MasteryStore.confidentMistakes(records: mastery.records).compactMap { byID[$0] }
            .filter { !premiumStore.isLocked($0.category) }
        VStack(alignment: .leading, spacing: 16) {
            if let calibration = mastery.calibration() {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How well you know what you know").font(.headline)
                    Text("When you say Sure, you're right \(Int((calibration * 100).rounded()))% of the time.")
                        .font(.subheadline)
                    Text(calibration >= 0.9 ? "Well calibrated: trust your Sure answers."
                         : "Some Sure answers are wrong. Those are worth a second look below.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            if !confident.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mistakes you were sure about").font(.headline)
                    Text("These are the easiest to fix now that you've seen the answer.").font(.caption).foregroundStyle(.secondary)
                    ForEach(confident.prefix(5)) { lesson in
                        NavigationLink { LessonHistoryView(lesson: lesson) } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text(lesson.term).font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            QuizHistoryExportButton()
            if let weakest = mastery.weakestKinds.first {
                Button {
                    let recent = TargetedDrill.recentLessonIDs(store.lessonActivity, limit: 12).compactMap { byID[$0] }
                        .filter { !premiumStore.isLocked($0.category) }
                    drill = TargetedDrill.questions(kind: weakest.kind, lessons: recent, all: lessons)
                    drillTitle = weakest.kind.label
                    showingDrill = !drill.isEmpty
                } label: {
                    Label("Practise \"\(weakest.kind.label)\" questions", systemImage: "target")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.bordered).tint(.indigo)
            }
        }
        .sheet(isPresented: $showingDrill) {
            LessonQuizView(lesson: nil, questions: drill, title: drillTitle) { result in
                for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                store.recordPractice()
            }
        }
    }
}

// MARK: - Focus timer

struct FocusTimerView: View {
    @ObservedObject private var focus = FocusStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var length = 15
    @State private var start: Date?
    @State private var finished = false

    var body: some View {
        VStack(spacing: 24) {
            if let start {
                TimelineView(.periodic(from: start, by: 1)) { context in
                    let progress = FocusMath.progress(start: start, minutes: length, now: context.date)
                    ZStack {
                        Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 14)
                        Circle().trim(from: 0, to: progress)
                            .stroke(Color.mint, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
                        Text(FocusMath.remainingText(start: start, minutes: length, now: context.date))
                            .font(.system(size: 52, weight: .bold, design: .rounded).monospacedDigit())
                    }
                    .frame(width: 240, height: 240)
                    .accessibilityElement()
                    .accessibilityLabel("Focus session, \(FocusMath.remainingText(start: start, minutes: length, now: context.date)) left")
                    .onChange(of: progress >= 1) { _, done in if done { complete(now: context.date) } }
                }
                Text("Phone face down, one lesson at a time.").foregroundStyle(.secondary)
                Button("End early", role: .destructive) { complete(now: Date()) }.buttonStyle(.bordered)
            } else {
                if finished {
                    Label("Session done. Nice focus.", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(.green)
                }
                Picker("Length", selection: $length) {
                    ForEach(FocusMath.lengths, id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)
                Button {
                    start = Date()
                    finished = false
                    HapticManager.shared.selection()
                } label: {
                    Label("Start focus session", systemImage: "play.fill").font(.headline)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(.mint)
                Text("Short, distraction-free blocks with a clear end are easier to start and to repeat.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            HStack(spacing: 24) {
                stat("Today", focus.minutes())
                stat("Last 7 days", focus.minutesThisWeek())
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: 600)
        .navigationTitle("Focus timer")
        .modifier(SprintTheme())
        .onDisappear { if start != nil { complete(now: Date()) } }
    }

    private func stat(_ title: String, _ minutes: Int) -> some View {
        VStack {
            Text("\(minutes) min").font(.title3.bold().monospacedDigit())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func complete(now: Date) {
        guard let start else { return }
        focus.record(minutes: FocusMath.focusedMinutes(start: start, minutes: length, now: now))
        finished = FocusMath.progress(start: start, minutes: length, now: now) >= 1
        self.start = nil
        if finished { HapticManager.shared.notification(.success) }
    }
}

/// Links for Practice: glossary, placement, focus timer.
struct StudyToolsSection: View {
    @AppStorage("goal.startingTrack") private var startingTrack = "Web development"
    @AppStorage(ArcadeKeys.relaxedReading) private var relaxedReading = false
    @State private var placementTrack: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study tools").font(.title3.bold())
            link("My terms", "Every term you've learned, with memory strength and your notes", "character.book.closed.fill") { MyTermsView() }
            link("Focus timer", "10, 15 or 25 minutes of distraction-free study", "timer") { FocusTimerView() }
            link("Reflections", "Your one-line notes on what you learned each day", "book.closed.fill") { JournalView() }
            Toggle(isOn: $relaxedReading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Relaxed reading").font(.headline)
                    Text("More space between lines and letters in lesson text").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Button { placementTrack = startingTrack } label: {
                row("Placement check", "Skip lessons you already know in \(startingTrack)", "forward.end.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .sheet(item: Binding(get: { placementTrack.map(TrackID.init) }, set: { placementTrack = $0?.id })) { item in
            PlacementCheckView(track: item.id)
        }
    }

    private struct TrackID: Identifiable { let id: String }

    private func link<D: View>(_ title: String, _ subtitle: String, _ icon: String,
                               @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination) { row(title, subtitle, icon) }.buttonStyle(.plain)
    }

    private func row(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(.mint).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(14)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
