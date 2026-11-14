import FoundationModels
import SwiftUI

// MARK: - Practice tab
//
// The Practice tab used to be only the Bite chat, which needs Apple Intelligence,
// so on most devices the whole tab was a dead end. Review works everywhere and
// is the default; the chat stays one tap away where the device supports it.

struct PracticeTabView: View {
    @AppStorage("practice.pane") private var pane = Pane.review.rawValue

    enum Pane: String, CaseIterable, Identifiable {
        case review, chat
        var id: String { rawValue }
        var label: String { self == .review ? "Review" : "Chat with Bite" }
    }

    private var aiAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Practice mode", selection: $pane) {
                ForEach(Pane.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.vertical, 10)

            if pane == Pane.chat.rawValue {
                if aiAvailable {
                    BitPracticeView()
                } else {
                    ContentUnavailableView {
                        Label("Bite needs Apple Intelligence", systemImage: "sparkles")
                    } description: {
                        Text("Chatting with Bite runs on device and needs Apple Intelligence turned on in Settings. Review works on every device.")
                    } actions: {
                        Button("Go to Review") { pane = Pane.review.rawValue }.buttonStyle(.borderedProminent)
                    }
                    .frame(maxHeight: .infinity)
                }
            } else {
                ReviewHubView()
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(SprintTheme())
    }
}

// MARK: - Review hub

struct ReviewHubView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var reviews = SM2Engine.shared
    @ObservedObject private var adaptive = AdaptiveEngine.shared
    @State private var showingPaywall = false
    @State private var mixSeed = UUID().uuidString

    private var lessons: [Lesson] { store.curriculum?.lessons ?? [] }
    private var tracks: [String] { store.tracks }
    private func isLocked(_ track: String) -> Bool { PremiumStore.proTracks.contains(track) && !premiumStore.isPro }
    private var due: [Lesson] { reviews.dueCards(in: lessons).filter { !isLocked($0.category) } }

    private func questions(for track: String) -> [Question] { store.quiz(for: track) }

    /// Ten questions drawn from tracks the learner has started (or every unlocked track if none).
    private var quickMix: [Question] {
        let started = Set(lessons.filter { store.completed.contains($0.id) }.map(\.category))
        let pool = tracks.filter { !isLocked($0) && (started.isEmpty || started.contains($0)) }
        var rng = SeededGenerator(seed: mixSeed)
        return Array(pool.flatMap { TrackQuiz.termQuestions(track: $0, lessons: lessons) }
            .shuffled(using: &rng).prefix(10))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                dueSection
                weakSection
                mistakesSection
                quickSection
                tracksSection
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 110)
            .frame(maxWidth: 700)
        }
        .sheet(isPresented: $showingPaywall) { ProPaywallView() }
    }

    private var dueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Due for review").font(.title3.bold())
            if due.isEmpty {
                Text(reviews.cards.isEmpty
                     ? "Lessons you finish come back here on a schedule, so you remember them."
                     : "Nothing due right now. Next review: \(nextReviewLabel).")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(due.prefix(8)) { lesson in
                    NavigationLink { LessonView(lesson: lesson) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(lesson.term).font(.headline)
                                Text(lesson.category).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                if due.count > 8 {
                    Text("+ \(due.count - 8) more after these").font(.caption).foregroundStyle(.secondary)
                }
                NavigationLink { ReviewSessionView(queue: due) } label: {
                    Label(due.count == 1 ? "Review it now" : "Review all \(due.count) in a row", systemImage: "play.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(.orange)
            }
        }
    }

    /// Terms the learner keeps missing, as a focused quiz.
    @ViewBuilder
    private var weakSection: some View {
        let weak = reviews.weakest(in: lessons.filter { !isLocked($0.category) })
        if weak.count >= 2 {
            let ids = Set(weak.map(\.id))
            let tracks = Set(weak.map(\.category))
            let qs = tracks.flatMap { TrackQuiz.termQuestions(track: $0, lessons: lessons) }
                .filter { TrackQuiz.lessonID(forQuestion: $0.id).map(ids.contains) ?? false }
            VStack(alignment: .leading, spacing: 10) {
                Text("Tricky ones").font(.title3.bold())
                Text(weak.map(\.term).joined(separator: " · ")).font(.subheadline).foregroundStyle(.secondary)
                if !qs.isEmpty {
                    NavigationLink { QuizView(questions: qs.shuffled(), title: "Tricky ones") } label: {
                        Label("Quiz me on these \(qs.count)", systemImage: "scope")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered).tint(.orange)
                }
            }
        }
    }

    /// Questions the learner has got wrong more often than right, from every quiz.
    private var mistakes: [Question] {
        let counts = adaptive.wrongCounts
        guard !counts.isEmpty else { return [] }
        let pool = tracks.filter { !isLocked($0) }.flatMap { store.quiz(for: $0) }
        return pool.filter { (counts[$0.id] ?? 0) > 0 }
            .sorted { (counts[$0.id] ?? 0) > (counts[$1.id] ?? 0) }
    }

    @ViewBuilder
    private var mistakesSection: some View {
        let list = mistakes
        if !list.isEmpty {
            NavigationLink { MistakesView(questions: list) } label: {
                HStack {
                    Image(systemName: "exclamationmark.bubble.fill").foregroundStyle(.red.opacity(0.8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your mistakes").font(.headline)
                        Text("\(list.count) \(list.count == 1 ? "question" : "questions") to look at again").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(14)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var nextReviewLabel: String {
        guard let soonest = reviews.cards.values.map(\.dueDate).min() else { return "soon" }
        return soonest.formatted(.relative(presentation: .named))
    }

    @ViewBuilder
    private var quickSection: some View {
        let mix = quickMix
        if !mix.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick round").font(.title3.bold())
                NavigationLink {
                    QuizView(questions: mix, title: "Quick round")
                        .onDisappear { mixSeed = UUID().uuidString }
                } label: {
                    Label("10 questions from your tracks", systemImage: "bolt.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent).tint(.mint)
            }
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quiz by track").font(.title3.bold())
            ForEach(tracks, id: \.self) { track in
                if isLocked(track) {
                    Button { showingPaywall = true } label: { trackRow(track, count: nil) }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(track) quiz, requires StackSprint Pro")
                } else {
                    let qs = questions(for: track)
                    NavigationLink { QuizView(questions: qs, title: "\(track) quiz", bestScoreID: "track.\(track)") } label: { trackRow(track, count: qs.count) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private func trackRow(_ track: String, count: Int?) -> some View {
        HStack {
            Text(track).font(.headline)
            Spacer()
            if let count {
                if let best = UserDefaults.standard.object(forKey: QuizView.bestKey("track.\(track)")) as? Int {
                    Text("best \(best)/\(count)").font(.caption.monospacedDigit()).foregroundStyle(.mint)
                } else {
                    Text("\(count) questions").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
            } else {
                Label("Pro", systemImage: "lock.fill").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(14)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Mistakes

struct MistakesView: View {
    let questions: [Question]

    var body: some View {
        List {
            Section {
                NavigationLink { QuizView(questions: Array(questions.prefix(15)).shuffled(), title: "Mistakes quiz") } label: {
                    Label("Quiz me on \(min(questions.count, 15)) of these", systemImage: "arrow.uturn.backward")
                }
            }
            Section("Questions you've missed") {
                ForEach(questions.prefix(40)) { q in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(q.question).font(.subheadline.bold())
                        Text("Answer: \(q.choices[q.answer])").font(.subheadline).foregroundStyle(.green)
                        Text(q.explanation).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Your mistakes")
        .modifier(SprintTheme())
    }
}
