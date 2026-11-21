import StoreKit
import SwiftUI
import UserNotifications

// MARK: - Checkpoints and exams

struct TrackTestsView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var exams = ExamStore.shared
    @State private var running: ExamUnit?
    @State private var questions: [LessonQuizQuestion] = []

    private var tracks: [String] { store.tracks.filter { !premiumStore.isLocked($0) } }

    var body: some View {
        List {
            Section {
                Text("Checkpoints test four lessons at once. The final exam covers the whole track. Pass mark: \(Exams.passPercent)%.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(tracks, id: \.self) { track in
                let lessons = store.lessonsByTrack[track] ?? []
                Section(track) {
                    ForEach(Exams.units(track: track, lessons: lessons) + [Exams.finalExam(track: track, lessons: lessons)]) { unit in
                        row(unit, lessons: lessons)
                    }
                }
            }
        }
        .navigationTitle("Checkpoints & exams")
        .modifier(SprintTheme())
        .sheet(item: $running) { unit in
            LessonQuizView(lesson: nil, questions: questions, title: "\(unit.track): \(unit.title)") { result in
                exams.record(unit, score: result.score, total: result.total)
                for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                store.recordPractice()
            }
        }
    }

    private func row(_ unit: ExamUnit, lessons: [Lesson]) -> some View {
        let open = Exams.isOpen(unit, completed: store.completed)
        let best = exams.best[unit.id]
        let passed = exams.hasPassed(unit)
        return Button {
            questions = Exams.questions(for: unit, lessons: store.curriculum?.lessons ?? lessons)
            if !questions.isEmpty { running = unit }
        } label: {
            HStack {
                Image(systemName: passed ? "checkmark.seal.fill" : (unit.isFinal ? "graduationcap.fill" : "flag.checkered"))
                    .foregroundStyle(passed ? Color.green : (open ? Color.mint : Color.secondary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.title).font(.headline)
                    Text(subtitle(unit, open: open, best: best)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if !open { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
            }
        }
        .disabled(!open)
        .accessibilityValue(passed ? "Passed" : (open ? "Ready" : "Locked"))
    }

    private func subtitle(_ unit: ExamUnit, open: Bool, best: Int?) -> String {
        let count = unit.isFinal ? Exams.finalQuestions : Exams.checkpointQuestions
        if let best { return "Best \(best)% · \(count) questions" }
        if open { return "\(count) questions · ready" }
        return unit.isFinal ? "Finish \(Exams.passPercent)% of the track to unlock" : "Finish lessons \(unit.lessonIDs.count == Exams.unitSize ? "in this group" : "above") to unlock"
    }
}

// MARK: - Bookmarks quiz

struct BookmarksQuizButton: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var bookmarks: BookmarkStore
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var questions: [LessonQuizQuestion] = []
    @State private var showing = false

    private var lessons: [Lesson] {
        (store.curriculum?.lessons ?? []).filter { bookmarks.bookmarks.contains($0.id) && !premiumStore.isLocked($0.category) }
    }

    var body: some View {
        Button {
            questions = MixedReview.questions(for: lessons, all: store.curriculum?.lessons ?? [], count: min(10, lessons.count * 2))
            showing = !questions.isEmpty
        } label: {
            toolRow("Quiz my bookmarks", lessons.count < 2 ? "Bookmark at least 2 lessons first" : "\(lessons.count) saved lessons, mixed together",
                    "bookmark.circle.fill")
        }
        .buttonStyle(.plain)
        .disabled(lessons.count < 2)
        .sheet(isPresented: $showing) {
            LessonQuizView(lesson: nil, questions: questions, title: "Bookmarks quiz") { result in
                for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                store.recordPractice()
            }
        }
    }
}

/// Row style shared by the study tool links.
func toolRow(_ title: String, _ subtitle: String, _ icon: String) -> some View {
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

// MARK: - Cheat sheets

struct CheatSheetView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var track = ""
    @State private var pdfURL: URL?

    private var tracks: [String] { store.tracks.filter { !premiumStore.isLocked($0) } }

    var body: some View {
        let lines = CheatSheet.lines(track: track, lessons: store.curriculum?.lessons ?? [], completed: store.completed)
        List {
            Picker("Track", selection: $track) {
                ForEach(tracks, id: \.self) { Text($0).tag($0) }
            }
            if lines.isEmpty {
                ContentUnavailableView("Finish a lesson in \(track) first", systemImage: "doc.text")
            } else {
                Section("\(lines.count) terms") {
                    ForEach(lines, id: \.term) { line in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line.term).font(.subheadline.bold())
                            Text(line.summary).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Cheat sheet")
        .modifier(SprintTheme())
        .toolbar {
            if let pdfURL, !lines.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: pdfURL) { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                }
            }
        }
        .onAppear { if track.isEmpty { track = tracks.first ?? "" } }
        .task(id: track) { pdfURL = makePDF(lines: lines) }
    }

    /// A one-page (or longer) PDF of the sheet, made with the same drawing as the screen.
    private func makePDF(lines: [(term: String, summary: String)]) -> URL? {
        guard !lines.isEmpty else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("StackSprint \(track) cheat sheet.pdf")
        let renderer = ImageRenderer(content: CheatSheetPage(track: track, lines: lines))
        var ok = false
        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let context = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            context.beginPDFPage(nil)
            draw(context)
            context.endPDFPage()
            context.closePDF()
            ok = true
        }
        return ok ? url : nil
    }
}

struct CheatSheetPage: View {
    let track: String
    let lines: [(term: String, summary: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(track) cheat sheet").font(.system(size: 22, weight: .bold))
            Text("Made with StackSprint").font(.caption).foregroundStyle(.gray)
            Divider()
            ForEach(lines, id: \.term) { line in
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.term).font(.system(size: 12, weight: .bold))
                    Text(line.summary).font(.system(size: 11))
                }
            }
        }
        .padding(36)
        .frame(width: 612, alignment: .topLeading)
        .background(Color.white)
        .foregroundStyle(.black)
    }
}

// MARK: - Display settings (study tools)

struct DisplaySettingsSection: View {
    @AppStorage(ArcadeKeys.relaxedReading) private var relaxedReading = false
    @AppStorage(DisplayPrefs.calmKey) private var calmMode = false
    @AppStorage(DisplayPrefs.colorBlindKey) private var colorBlind = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            toggle("Relaxed reading", "More space between lines and letters in lesson text", $relaxedReading)
            Divider().padding(.leading, 14)
            toggle("Calm mode", "Hide XP, streak counts and combo badges after quizzes", $calmMode)
            Divider().padding(.leading, 14)
            toggle("Colour-blind friendly", "Show right and wrong in blue and orange instead of green and red", $colorBlind)
        }
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func toggle(_ title: String, _ subtitle: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }
}

// MARK: - Share a result (session complete)

struct ShareResultButton: View {
    let lesson: Lesson
    let result: LessonQuizResult

    var body: some View {
        ShareLink(item: "I just scored \(result.score)/\(result.total) on \(lesson.term) in StackSprint. Learning a little every day.") {
            Label("Share my result", systemImage: "square.and.arrow.up")
                .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Trial reminder (account)

struct TrialReminderRow: View {
    @AppStorage(TrialReminder.enabledKey) private var enabled = false
    @State private var trial: (plan: String, ends: Date, price: String)?

    var body: some View {
        Group {
            if let trial {
                Toggle(isOn: $enabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remind me before my trial ends")
                        Text("\(trial.plan) trial ends \(trial.ends.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onChange(of: enabled) { _, on in schedule(on: on, trial: trial) }
            }
        }
        .task { await load() }
    }

    private func load() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.productType == .autoRenewable,
                  transaction.offer?.type == .introductory, transaction.offer?.paymentMode == .freeTrial,
                  let ends = transaction.expirationDate, ends > Date(),
                  let id = StoreProductID(rawValue: transaction.productID) else { continue }
            let price = (try? await Product.products(for: [transaction.productID]).first?.displayPrice) ?? "the regular price"
            trial = (id.offer.title, ends, price)
            if enabled { schedule(on: true, trial: (id.offer.title, ends, price)) }
            return
        }
        trial = nil
    }

    private func schedule(on: Bool, trial: (plan: String, ends: Date, price: String)) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [TrialReminder.id])
        guard on, let date = TrialReminder.fireDate(trialEnds: trial.ends) else { return }
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            let content = UNMutableNotificationContent()
            content.title = "Your free trial ends soon"
            content.body = TrialReminder.body(plan: trial.plan, price: trial.price, ends: trial.ends)
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            try? await center.add(UNNotificationRequest(identifier: TrialReminder.id, content: content,
                                                        trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
        }
    }
}

// MARK: - Study break banner (root)

struct StudyBreakBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill").font(.title3).foregroundStyle(.mint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Time for a short break").font(.subheadline.bold())
                Text("25 minutes in. A 5-minute break helps it sink in.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("OK", action: onDismiss).buttonStyle(.bordered)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
