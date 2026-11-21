import SwiftUI

// MARK: - Brain dump

struct BrainDumpView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var dumps = BrainDumpStore.shared
    @State private var track = ""
    @State private var text = ""
    @State private var result: BrainDumpResult?
    @FocusState private var focused: Bool

    private var tracks: [String] {
        store.tracks.filter { t in !premiumStore.isLocked(t) && (store.lessonsByTrack[t] ?? []).contains { store.completed.contains($0.id) } }
    }

    private var terms: [String] {
        (store.lessonsByTrack[track] ?? []).filter { store.completed.contains($0.id) }.map(\.term)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if tracks.isEmpty {
                    ContentUnavailableView("Finish a lesson first", systemImage: "brain",
                                           description: Text("Then come back and write down everything you remember."))
                } else {
                    Picker("Track", selection: $track) {
                        ForEach(tracks, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    Text("Write down every \(track) term and idea you remember, in any order. No peeking.")
                        .foregroundStyle(.secondary)
                    Text("You've finished \(terms.count) \(terms.count == 1 ? "lesson" : "lessons") in this track.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $text)
                        .focused($focused)
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityLabel("Everything you remember about \(track)")
                        .onChange(of: text) { _, _ in result = nil }
                    Button("Check what I remembered") { check() }
                        .buttonStyle(.borderedProminent).tint(.mint)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if let result { resultView(result) }
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle("Brain dump")
        .modifier(SprintTheme())
        .onAppear { if track.isEmpty { track = tracks.first ?? "" } }
        .onChange(of: track) { _, _ in text = ""; result = nil }
    }

    @ViewBuilder
    private func resultView(_ result: BrainDumpResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You recalled \(result.recalled.count) of \(result.recalled.count + result.missed.count) (\(result.percent)%)")
                .font(.title3.bold())
            if let best = dumps.best[track] { Text("Best for \(track): \(best)%").font(.caption).foregroundStyle(.secondary) }
            if !result.missed.isEmpty {
                Text("Worth another look").font(.headline)
                Text(result.missed.joined(separator: " · ")).font(.subheadline)
            }
            Text("Writing from memory is hard, and that's why it works. Whatever you couldn't recall today is what to review next.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func check() {
        focused = false
        let r = BrainDump.score(text: text, terms: terms)
        result = r
        dumps.record(track: track, percent: r.percent)
        store.recordPractice()
        HapticManager.shared.notification(.success)
        AccessibilityNotification.Announcement("You recalled \(r.recalled.count) of \(r.recalled.count + r.missed.count)").post()
    }
}

// MARK: - Week in review

struct WeekInReviewButton: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var questions: [LessonQuizQuestion] = []
    @State private var showing = false

    private var lessons: [Lesson] {
        let byID = Dictionary((store.curriculum?.lessons ?? []).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return WeekInReview.lessonIDs(activity: store.lessonActivity).compactMap { byID[$0] }
            .filter { !premiumStore.isLocked($0.category) }
    }

    var body: some View {
        let count = lessons.count
        Button {
            questions = MixedReview.questions(for: lessons, all: store.curriculum?.lessons ?? [], count: min(10, count * 2))
            showing = !questions.isEmpty
        } label: {
            toolRow("Week in review", count < 2 ? "Study 2 or more lessons this week to unlock" : "10 questions on the \(count) lessons you studied this week",
                    "calendar.badge.checkmark")
        }
        .buttonStyle(.plain)
        .disabled(count < 2)
        .sheet(isPresented: $showing) {
            LessonQuizView(lesson: nil, questions: questions, title: "Week in review") { result in
                for missed in result.missed { AdaptiveEngine.shared.recordWrong(missed.id) }
                store.recordPractice()
            }
        }
    }
}

// MARK: - Next certificate card (Learn)

struct NextCertificateCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var mastery = MasteryStore.shared

    var body: some View {
        if let goal = NextCertificate.closest(lessonsByTrack: store.lessonsByTrack, locked: premiumStore.lockedTracks,
                                              completed: store.completed, best: { mastery.best($0) }),
           goal.remaining <= max(3, goal.total / 3) {
            NavigationLink { CertificatesView() } label: {
                HStack(spacing: 14) {
                    Image(systemName: "rosette").font(.title).foregroundStyle(.yellow)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NextCertificate.message(goal)).font(.headline).multilineTextAlignment(.leading)
                        ProgressView(value: Double(goal.total - goal.remaining), total: Double(goal.total)).tint(.yellow)
                        Text("Finish each lesson and score 4/5 or better on its quiz.").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Solid lessons (memory)

struct SolidLessonsCard: View {
    @ObservedObject private var mastery = MasteryStore.shared

    var body: some View {
        let solid = Solid.solidCount(mastery.records)
        let started = mastery.records.count
        if started > 0 {
            VStack(alignment: .leading, spacing: 6) {
                Label("\(solid) solid \(solid == 1 ? "lesson" : "lessons")", systemImage: "checkmark.shield.fill")
                    .font(.headline).foregroundStyle(.green)
                Text("A lesson is solid once you've scored 4/5 or better on \(Solid.daysNeeded) different days. Relearning across days is what makes memories last for months.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Saved prompts

struct SavePromptButton: View {
    let prompt: String
    @ObservedObject private var library = PromptLibrary.shared
    @State private var saved = false

    var body: some View {
        Button(saved ? "Saved to My prompts" : "Save to My prompts", systemImage: saved ? "checkmark" : "tray.and.arrow.down") {
            saved = library.save(title: "", text: prompt)
            if saved { HapticManager.shared.notification(.success) }
        }
        .disabled(saved || !PromptCheck.privacyWarnings(prompt).isEmpty)
        .onChange(of: prompt) { _, _ in saved = false }
    }
}

struct PromptLibraryView: View {
    @ObservedObject private var library = PromptLibrary.shared
    @State private var copiedID: UUID?

    var body: some View {
        List {
            if library.prompts.isEmpty {
                ContentUnavailableView("No saved prompts yet", systemImage: "tray",
                                       description: Text("Build one in the Prompt builder and tap Save to My prompts."))
            }
            ForEach(library.prompts) { prompt in
                VStack(alignment: .leading, spacing: 6) {
                    Text(prompt.title).font(.headline)
                    Text(prompt.text).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary).lineLimit(4)
                    HStack {
                        Button(copiedID == prompt.id ? "Copied" : "Copy", systemImage: copiedID == prompt.id ? "checkmark" : "doc.on.doc") {
                            UIPasteboard.general.string = prompt.text
                            copiedID = prompt.id
                        }
                        .buttonStyle(.bordered)
                        ShareLink(item: prompt.text) { Image(systemName: "square.and.arrow.up") }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Share prompt")
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                for i in offsets { library.delete(library.prompts[i].id) }
            }
        }
        .navigationTitle("My prompts")
        .modifier(SprintTheme())
        .toolbar { if !library.prompts.isEmpty { EditButton() } }
    }
}

// MARK: - Code review and commit drills

struct ReviewDrillView: View {
    let title: String
    let items: [ReviewItem]
    @EnvironmentObject var store: LearningStore
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if items.indices.contains(index) {
                    let item = items[index]
                    Text("\(index + 1) of \(items.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
                    Text(item.context).font(.headline)
                    if !item.snippet.isEmpty {
                        Text(item.snippet).font(.system(.callout, design: .monospaced))
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Text("What's the best response?").font(.title3.bold())
                    ForEach(item.options.indices, id: \.self) { i in
                        Button {
                            picked = i
                            if i == item.best { score += 1 }
                            if index + 1 == items.count { store.recordPractice() }
                            HapticManager.shared.notification(i == item.best ? .success : .warning)
                        } label: {
                            HStack {
                                Text(item.options[i]).multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                if picked != nil && i == item.best { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                                else if picked == i { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                            }
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(picked != nil)
                    }
                    if picked != nil {
                        Text(item.why).fixedSize(horizontal: false, vertical: true)
                        Button(index + 1 < items.count ? "Next" : "Finish") { picked = nil; index += 1 }
                            .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                } else {
                    Text("\(score) of \(items.count) best calls").font(.largeTitle.bold())
                    Button("Practice again") { index = 0; score = 0; picked = nil }.buttonStyle(.borderedProminent)
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle(title)
        .modifier(SprintTheme())
    }
}

// MARK: - Appearance picker (menu)

struct AppearanceMenuSection: View {
    @Binding var appearance: String

    var body: some View {
        Picker("Appearance", selection: $appearance) {
            ForEach(AppearanceMode.options, id: \.id) { option in
                Label(option.title, systemImage: option.icon).tag(option.id)
            }
        }
    }
}
