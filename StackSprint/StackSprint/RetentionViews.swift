import Charts
import SwiftUI

// MARK: - Explain it back (in the lesson)

/// Write the idea in your own words, then see which key ideas you covered.
struct ExplainBackCard: View {
    let lesson: Lesson
    @ObservedObject private var notes = ExplainBackStore.shared
    @State private var text = ""
    @State private var checked = false
    @State private var expanded = false
    @FocusState private var focused: Bool

    private var ideas: [String] { ExplainBack.keyIdeas(for: lesson) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Label("Explain it in your own words", systemImage: "text.bubble.fill").font(.headline)
                    Spacer()
                    if notes.notes[lesson.id] != nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(expanded ? "Collapses" : "Expands a box to write your explanation")

            if expanded {
                Text("Pretend you're teaching a friend. Explaining is one of the best ways to understand something, and it shows you what you've missed.")
                    .font(.subheadline).foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .focused($focused)
                    .frame(minHeight: 110)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("\(lesson.term) is…").foregroundStyle(.tertiary).padding(16).allowsHitTesting(false)
                        }
                    }
                    .accessibilityLabel("Your explanation of \(lesson.term)")
                    .onChange(of: text) { _, _ in checked = false }
                Button("Check my explanation") {
                    focused = false
                    checked = true
                    notes.save(text, for: lesson.id)
                    HapticManager.shared.selection()
                    AccessibilityNotification.Announcement(summary).post()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if checked { result }
            }
        }
        .padding(16)
        .background(Color.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { if text.isEmpty { text = notes.notes[lesson.id] ?? "" } }
    }

    private var covered: [String] { ExplainBack.covered(text, ideas: ideas) }

    private var summary: String {
        guard ExplainBack.isSubstantial(text) else { return "Try a little more: aim for two full sentences." }
        if ideas.isEmpty || covered.count == ideas.count { return "You covered the key ideas." }
        return "You covered \(covered.count) of \(ideas.count) key ideas."
    }

    @ViewBuilder
    private var result: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary).font(.subheadline.bold())
            if !ideas.isEmpty {
                FlowChips(items: ideas.map { idea in (idea, covered.contains(idea)) })
                if covered.count < ideas.count {
                    Text("Compare with the explanation above. Could you work the missing ideas in?")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("Saved with this lesson. Only you can see it.").font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Small wrap-around chips; green when covered.
private struct FlowChips: View {
    let items: [(String, Bool)]
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { chips }
            VStack(alignment: .leading, spacing: 6) { chips }
        }
    }
    @ViewBuilder private var chips: some View {
        ForEach(items, id: \.0) { item in
            Label(item.0, systemImage: item.1 ? "checkmark" : "circle.dashed")
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(item.1 ? Color.green.opacity(0.15) : SprintPalette.card, in: Capsule())
                .foregroundStyle(item.1 ? Color.green : Color.secondary)
                .accessibilityLabel("\(item.0), \(item.1 ? "covered" : "not covered yet")")
        }
    }
}

// MARK: - Next-day retest (home)

/// "Yesterday you learned X": a fresh 5-question check a day or more later.
struct RetestCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var mastery = MasteryStore.shared
    @State private var showing = false
    @State private var lessonID: String?

    private var lessons: [Lesson] { store.curriculum?.lessons ?? [] }

    private var candidate: Lesson? {
        let allowed = Set(lessons.filter { !premiumStore.isLocked($0.category) }.map(\.id))
        guard let id = Retest.candidate(records: mastery.records, allowed: allowed) else { return nil }
        return lessons.first { $0.id == id }
    }

    var body: some View {
        if let lesson = candidate {
            Button {
                lessonID = lesson.id
                showing = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "arrow.uturn.backward.circle.fill").font(.title).foregroundStyle(.indigo)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Still remember \(lesson.term)?").font(.headline)
                        Text("A quick 5-question check, a day or two later, is when testing helps most.")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retest: \(lesson.term). Five questions.")
            .sheet(isPresented: $showing) {
                if let id = lessonID, let lesson = lessons.first(where: { $0.id == id }) {
                    let base = LessonQuizBuilder.build(for: lesson, in: store.lessonsByTrack[lesson.category] ?? [])
                    LessonQuizView(lesson: lesson,
                                   questions: Retest.reshuffled(base, seed: "retest|\(id)|\(LearningStore.dayKey(Date()))"),
                                   title: "Retest") { result in
                        LessonQuizRecorder.record(id, result)
                        for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                        store.recordPractice()
                    }
                }
            }
        }
    }
}

// MARK: - Mixed review (review hub)

struct MixedReviewSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var reviews = SM2Engine.shared
    @State private var showing = false
    @State private var questions: [LessonQuizQuestion] = []

    private var picked: [Lesson] {
        let lessons = (store.curriculum?.lessons ?? []).filter {
            store.completed.contains($0.id) && !premiumStore.isLocked($0.category)
        }
        let candidates = lessons.map { lesson in
            (lesson: lesson, recall: reviews.card(for: lesson.id).map { MemoryModel.recall(card: $0) } ?? 0.5)
        }
        return MixedReview.pickLessons(candidates)
    }

    var body: some View {
        let lessons = picked
        if lessons.count >= 3 {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mixed review").font(.title3.bold())
                Text("\(lessons.map(\.term).joined(separator: " · "))").font(.subheadline).foregroundStyle(.secondary)
                Button {
                    questions = MixedReview.questions(for: lessons, all: store.curriculum?.lessons ?? [])
                    showing = !questions.isEmpty
                } label: {
                    Label("10 questions, lessons mixed together", systemImage: "shuffle")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
                .buttonStyle(.bordered).tint(.indigo)
                Text("Your weakest lessons first, mixed so you practise telling them apart.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .sheet(isPresented: $showing) {
                LessonQuizView(lesson: nil, questions: questions, title: "Mixed review") { result in
                    for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                    store.recordPractice()
                }
            }
        }
    }
}

// MARK: - You vs. last week (analytics)

struct WeekComparisonCard: View {
    @EnvironmentObject var store: LearningStore

    var body: some View {
        let comparison = WeekComparison.make(activity: store.lessonActivity)
        VStack(alignment: .leading, spacing: 12) {
            Label("You vs. last week", systemImage: "figure.run").font(.headline)
            Chart {
                BarMark(x: .value("Lessons", comparison.lastWeek), y: .value("Week", "Last week"))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                BarMark(x: .value("Lessons", comparison.thisWeek), y: .value("Week", "This week"))
                    .foregroundStyle(Color.mint)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            .frame(height: 90)
            .accessibilityLabel("Lessons this week \(comparison.thisWeek), last week \(comparison.lastWeek)")
            Text(comparison.message).font(.subheadline).foregroundStyle(.secondary)
            BuddyShareButton()
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Study planner

struct StudyPlannerView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @AppStorage(StudyPlanner.trackKey) private var track = ""
    @AppStorage(StudyPlanner.dateKey) private var finishByInterval: Double = 0
    @State private var finishBy = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

    private var tracks: [String] { store.tracks.filter { !premiumStore.isLocked($0) } }

    var body: some View {
        Form {
            WhyPickerSection()
            Section {
                Picker("Track", selection: $track) {
                    Text("Choose a track").tag("")
                    ForEach(tracks, id: \.self) { Text($0).tag($0) }
                }
                DatePicker("Finish by", selection: $finishBy, in: Date()..., displayedComponents: .date)
                    .onChange(of: finishBy) { _, date in finishByInterval = date.timeIntervalSince1970 }
            } footer: {
                Text("A clear plan with a date makes it much more likely you'll follow through.")
            }
            if !track.isEmpty {
                let progress = store.progress(in: track)
                let total = progress.total
                let remaining = progress.total - progress.done
                Section("Your plan") {
                    LabeledContent("Lessons left", value: "\(remaining) of \(total)")
                    if let perDay = StudyPlanner.lessonsPerDay(remaining: remaining, finishBy: finishBy) {
                        if perDay == 0 {
                            Label("You've finished this track.", systemImage: "flag.checkered").foregroundStyle(.green)
                        } else {
                            Label("\(perDay) \(perDay == 1 ? "lesson" : "lessons") a day", systemImage: "calendar")
                                .font(.headline)
                            Text("Plus the reviews that come due. Reviews are what make finished lessons stick.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Study plan")
        .modifier(SprintTheme())
        .onAppear {
            if finishByInterval > 0 { finishBy = max(Date(), Date(timeIntervalSince1970: finishByInterval)) }
            if track.isEmpty || !tracks.contains(track) { track = tracks.first ?? "" }
        }
    }
}

// MARK: - Certificates

struct CertificatesView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @EnvironmentObject var socialAuth: SocialAuthManager
    @ObservedObject private var mastery = MasteryStore.shared

    private var tracks: [String] { store.tracks.filter { !premiumStore.isLocked($0) } }

    var body: some View {
        List {
            Section {
                Text("Finish every lesson in a track and score 4 or 5 out of 5 on each lesson quiz to earn its certificate.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(tracks, id: \.self) { track in
                let lessons = store.lessonsByTrack[track] ?? []
                let earned = TrackCertificate.isEarned(lessons: lessons, completed: store.completed, best: { mastery.best($0) })
                let progress = TrackCertificate.progress(lessons: lessons, completed: store.completed, best: { mastery.best($0) })
                HStack(spacing: 12) {
                    Image(systemName: earned ? "rosette" : "seal")
                        .font(.title2).foregroundStyle(earned ? Color.yellow : Color.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track).font(.headline)
                        Text(earned ? "Earned" : "\(progress) of \(lessons.count) lessons at 4/5 or better")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if earned, let image = certificateImage(track: track) {
                        ShareLink(item: image, preview: SharePreview("\(track) certificate", image: image)) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share your \(track) certificate")
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .navigationTitle("Certificates")
        .modifier(SprintTheme())
    }

    private func certificateImage(track: String) -> Image? {
        let renderer = ImageRenderer(content: CertificateArt(track: track, name: socialAuth.isSignedIn ? socialAuth.displayName : nil,
                                                             lessons: store.lessonsByTrack[track]?.count ?? 0))
        renderer.scale = 2
        guard let image = renderer.uiImage else { return nil }
        return Image(uiImage: image)
    }
}

/// The shareable certificate picture. Says plainly it's an in-app achievement.
struct CertificateArt: View {
    let track: String
    let name: String?
    let lessons: Int

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "rosette").font(.system(size: 54)).foregroundStyle(.yellow)
            Text("StackSprint").font(.headline).foregroundStyle(.white.opacity(0.8))
            Text(track).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(.white)
                .multilineTextAlignment(.center)
            if let name, !name.isEmpty {
                Text("Completed by \(name)").font(.title3).foregroundStyle(.white)
            }
            Text("All \(lessons) lessons finished, every lesson quiz passed at 4/5 or better.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.85)).multilineTextAlignment(.center)
            Text(Date().formatted(date: .long, time: .omitted)).font(.caption).foregroundStyle(.white.opacity(0.7))
            Text("An in-app learning achievement, not an accredited qualification.")
                .font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
        .padding(36)
        .frame(width: 600, height: 420)
        .background(LinearGradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.22), .indigo],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}
