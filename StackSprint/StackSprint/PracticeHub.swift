import FoundationModels
import SwiftUI

// MARK: - Practice tab
//
// The Practice tab used to be only the Bit chat, which needs Apple Intelligence,
// so on most devices the whole tab was a dead end. Review works everywhere and
// is the default; the chat stays one tap away where the device supports it.

struct PracticeTabView: View {
    @AppStorage("practice.pane") private var pane = Pane.review.rawValue

    enum Pane: String, CaseIterable, Identifiable {
        case review, chat
        var id: String { rawValue }
        var label: String { self == .review ? "Review" : "Chat with Bit" }
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
                        Label("Bit needs Apple Intelligence", systemImage: "sparkles")
                    } description: {
                        Text("Chatting with Bit runs on device and needs Apple Intelligence turned on in Settings. Review works on every device.")
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
    @State private var showingPaywall = false
    @State private var mixSeed = UUID().uuidString

    private var lessons: [Lesson] { store.curriculum?.lessons ?? [] }
    private var tracks: [String] {
        var seen = Set<String>()
        return lessons.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }
    private func isLocked(_ track: String) -> Bool { PremiumStore.proTracks.contains(track) && !premiumStore.isPro }
    private var due: [Lesson] { reviews.dueCards(in: lessons).filter { !isLocked($0.category) } }

    private func questions(for track: String) -> [Question] {
        TrackQuiz.curated(track: track, questions: store.curriculum?.questions ?? [])
            + TrackQuiz.termQuestions(track: track, lessons: lessons)
    }

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
            }
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
                    NavigationLink { QuizView(questions: qs, title: "\(track) quiz") } label: { trackRow(track, count: qs.count) }
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
                Text("\(count) questions").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            } else {
                Label("Pro", systemImage: "lock.fill").font(.caption.bold()).foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(14)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
