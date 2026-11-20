import SwiftUI

// MARK: - Quick guess (before reading)
//
// Guessing before you're told primes memory, even when the guess is wrong, as long as
// the answer follows right away. No score, no XP: it's a warm-up.

struct QuickGuessCard: View {
    let question: LessonQuizQuestion
    let onDone: () -> Void
    @State private var picked: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick guess before you read", systemImage: "lightbulb.fill")
                .font(.footnote.weight(.semibold)).foregroundStyle(.orange)
            Text(question.prompt).font(.headline).fixedSize(horizontal: false, vertical: true)
            ForEach(question.choices.indices, id: \.self) { index in
                Button { pick(index) } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(question.choices[index]).font(.subheadline).multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        if picked != nil && index == question.answer {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        } else if picked == index {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.orange)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(fill(index), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(picked != nil)
            }
            if let picked {
                Text(picked == question.answer ? "Good instinct. Now read why." : "Not quite, and that's fine: guessing first helps it stick. Read on.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Show the explanation", action: onDone).buttonStyle(.borderedProminent)
            } else {
                Button("Skip the guess", action: onDone).font(.footnote).buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func fill(_ index: Int) -> Color {
        guard let picked else { return SprintPalette.card }
        if index == question.answer { return .green.opacity(0.15) }
        if index == picked { return .orange.opacity(0.15) }
        return SprintPalette.card
    }

    private func pick(_ index: Int) {
        picked = index
        HapticManager.shared.selection()
        AccessibilityNotification.Announcement(index == question.answer ? "Correct guess" : "The answer is \(question.choices[question.answer])").post()
    }
}

// MARK: - End-of-lesson quiz

struct LessonQuizResult {
    let score: Int
    let total: Int
    let missed: [LessonQuizQuestion]
    /// Right answers marked "guessing".
    var luckyGuesses = 0
    /// Wrong answers marked "sure".
    var confidentMisses = 0
    /// Every answer, in order, for the answer review.
    var answers: [QuizAnswer] = []
}

/// Quiz preferences, shared by every lesson quiz.
enum QuizPrefs {
    static let confidenceKey = "quiz.askConfidence"
    static let typedKey = "quiz.typedRecall"
}

struct LessonQuizView: View {
    /// The lesson being tested. Nil for a mixed session that covers several lessons.
    let lesson: Lesson?
    let questions: [LessonQuizQuestion]
    /// XP the lesson itself earned this visit (10 when it was finished for the first time).
    var lessonXP = 0
    /// Title for a mixed or retest session.
    var title = "Lesson quiz"
    let onFinish: (LessonQuizResult) -> Void

    @EnvironmentObject var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(QuizPrefs.confidenceKey) private var askConfidence = true
    @AppStorage(QuizPrefs.typedKey) private var typedRecall = false
    @State private var index = 0
    /// The revealed answer. -1 means a typed answer that didn't match.
    @State private var selected: Int?
    /// Picked but not yet revealed, while the learner says how sure they are.
    @State private var pending: Int?
    @State private var confidence: AnswerConfidence?
    @State private var typed = ""
    @State private var score = 0
    @State private var missed: [LessonQuizQuestion] = []
    @State private var lucky = 0
    @State private var confidentMisses = 0
    @State private var answers: [QuizAnswer] = []
    @State private var combo = 0
    @State private var quizXP = 0
    @State private var finished: LessonQuizResult?
    @FocusState private var typingFocused: Bool

    private var pool: [Lesson] {
        if let lesson { return store.lessonsByTrack[lesson.category] ?? [] }
        return store.curriculum?.lessons ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let finished {
                        if let lesson {
                            SessionCompleteView(lesson: lesson, result: finished, xpEarned: lessonXP + quizXP) { dismiss() }
                        } else {
                            MixedSummaryView(title: title, result: finished, xpEarned: quizXP) { dismiss() }
                        }
                    } else if questions.indices.contains(index) {
                        question(questions[index])
                    }
                }
                .padding(24)
                .frame(maxWidth: 700)
            }
            .navigationTitle(finished == nil ? title : "Session complete")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar {
                if finished == nil {
                    ToolbarItem(placement: .cancellationAction) { Button("Later") { dismiss() } }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Toggle("Ask how sure I am", isOn: $askConfidence)
                            Toggle("Type answers (harder)", isOn: $typedRecall)
                        } label: {
                            Label("Quiz options", systemImage: "slider.horizontal.3")
                        }
                        .disabled(pending != nil || selected != nil)
                    }
                }
            }
        }
        .interactiveDismissDisabled(finished == nil && index > 0)
    }

    private func isTyped(_ q: LessonQuizQuestion) -> Bool { typedRecall && q.kind == .recall }

    @ViewBuilder
    private func question(_ q: LessonQuizQuestion) -> some View {
        HStack {
            Text("\(index + 1) of \(questions.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
            Spacer()
            Text(q.kind.label).font(.caption.bold()).foregroundStyle(.mint)
            Button {
                VoiceManager.shared.speak(isTyped(q) ? q.prompt : ([q.prompt] + q.choices).joined(separator: ". "))
            } label: {
                Image(systemName: "speaker.wave.2.fill")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Read the question aloud")
        }
        ProgressView(value: Double(index), total: Double(questions.count)).tint(.mint)
        Text(q.prompt).font(.title3.bold()).fixedSize(horizontal: false, vertical: true)
        if isTyped(q) {
            typedField(q)
        } else {
            ForEach(q.choices.indices, id: \.self) { i in
                Button { choose(i) } label: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(q.choices[i]).multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        if selected != nil && i == q.answer { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                        else if selected == i { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                        else if pending == i { Image(systemName: "circle.inset.filled").foregroundStyle(.mint) }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(fill(i, q), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(pending == i ? Color.mint : Color.secondary.opacity(0.2), lineWidth: pending == i ? 2 : 1))
                }
                .buttonStyle(.plain)
                .disabled(selected != nil)
                .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                .accessibilityLabel(label(i, q))
            }
        }
        if pending != nil && selected == nil { confidencePrompt(q) }
        if let selected { feedback(q, selected) }
    }

    private func typedField(_ q: LessonQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Type the term", text: $typed)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($typingFocused)
                .padding(14)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .disabled(pending != nil || selected != nil)
                .onSubmit { submitTyped(q) }
                .onAppear { typingFocused = true }
                .accessibilityHint("Type your answer, then submit")
            if pending == nil && selected == nil {
                Button("Submit") { submitTyped(q) }
                    .buttonStyle(.borderedProminent)
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Text("Small typos are fine on longer terms.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func confidencePrompt(_ q: LessonQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How sure are you?").font(.headline)
            HStack(spacing: 12) {
                Button { reveal(q, confidence: .sure) } label: {
                    Label("Sure", systemImage: "hand.thumbsup.fill").frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent).tint(.mint)
                .keyboardShortcut("s", modifiers: [])
                Button { reveal(q, confidence: .guessing) } label: {
                    Label("Guessing", systemImage: "questionmark.circle").frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("g", modifiers: [])
            }
            Button("Change my answer") { pending = nil; if isTyped(q) { typingFocused = true } }
                .font(.footnote).buttonStyle(.plain).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.mint.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func feedback(_ q: LessonQuizQuestion, _ choice: Int) -> some View {
        let right = choice == q.answer
        HStack {
            Text(right ? "Right." : "The answer is \(q.choices[q.answer]).").font(.headline)
            if right, let cheer = QuizCombo.message(for: combo) {
                Spacer()
                Label(cheer, systemImage: "flame.fill").font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15), in: Capsule()).foregroundStyle(.orange)
            }
        }
        if right && confidence == .guessing {
            Label("Right, but you guessed. It'll come back a little sooner so it sticks.", systemImage: "questionmark.circle")
                .font(.subheadline).foregroundStyle(.orange)
        } else if !right && confidence == .sure {
            Label("You were sure about this one. Mistakes you were confident about are the easiest to fix once you see why.",
                  systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline).foregroundStyle(.orange)
        }
        if !right, q.choices.indices.contains(choice),
           let whyNot = LessonQuizBuilder.whyNot(q.choices[choice], in: q, lessons: pool) {
            Text(whyNot).font(.subheadline).fixedSize(horizontal: false, vertical: true)
        }
        Text(q.explanation).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        Button(index + 1 < questions.count ? "Next question" : "See results") { next() }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
    }

    private func choose(_ choice: Int) {
        HapticManager.shared.selection()
        if askConfidence {
            pending = choice
            AccessibilityNotification.Announcement("How sure are you?").post()
        } else {
            pending = choice
            reveal(questions[index], confidence: nil)
        }
    }

    private func submitTyped(_ q: LessonQuizQuestion) {
        guard !typed.trimmingCharacters(in: .whitespaces).isEmpty, selected == nil else { return }
        typingFocused = false
        let choice = TypedAnswer.matches(typed, q.choices[q.answer]) ? q.answer : -1
        if askConfidence {
            pending = choice
            AccessibilityNotification.Announcement("How sure are you?").post()
        } else {
            pending = choice
            reveal(q, confidence: nil)
        }
    }

    private func reveal(_ q: LessonQuizQuestion, confidence level: AnswerConfidence?) {
        guard let choice = pending else { return }
        confidence = level
        selected = choice
        pending = nil
        answers.append(QuizAnswer(question: q, chosen: choice, confidence: level))
        if choice == q.answer {
            score += 1
            combo += 1
            if level == .guessing { lucky += 1 }
            // Same rule as every quiz: 5 XP per question answered right, once a day.
            if store.recordDailyRecall(q.id) { quizXP += 5 }
            HapticManager.shared.notification(.success)
            AccessibilityNotification.Announcement("Correct").post()
        } else {
            missed.append(q)
            combo = 0
            if level == .sure { confidentMisses += 1 }
            HapticManager.shared.notification(.warning)
            AccessibilityNotification.Announcement("Not quite. The answer is \(q.choices[q.answer]).").post()
        }
    }

    private func next() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) {
            selected = nil
            pending = nil
            confidence = nil
            typed = ""
            index += 1
            if index >= questions.count {
                let result = LessonQuizResult(score: score, total: questions.count, missed: missed,
                                              luckyGuesses: lucky, confidentMisses: confidentMisses, answers: answers)
                finished = result
                onFinish(result)
            }
        }
    }

    private func fill(_ i: Int, _ q: LessonQuizQuestion) -> Color {
        guard let selected else { return pending == i ? Color.mint.opacity(0.10) : SprintPalette.card }
        if i == q.answer { return .green.opacity(0.16) }
        if i == selected { return .red.opacity(0.14) }
        return SprintPalette.card
    }

    private func label(_ i: Int, _ q: LessonQuizQuestion) -> String {
        guard let selected else { return pending == i ? "\(q.choices[i]), selected" : q.choices[i] }
        if i == q.answer { return "\(q.choices[i]), correct answer" }
        if i == selected { return "\(q.choices[i]), your answer, incorrect" }
        return q.choices[i]
    }
}

/// Results for a session that covered several lessons.
struct MixedSummaryView: View {
    let title: String
    let result: LessonQuizResult
    let xpEarned: Int
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(result.score) of \(result.total)").font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text(title).font(.title3)
            Label("+\(xpEarned) XP", systemImage: "bolt.fill").font(.headline).foregroundStyle(.yellow)
            if result.confidentMisses > 0 {
                Label("\(result.confidentMisses) answer\(result.confidentMisses == 1 ? "" : "s") you were sure about were wrong. Those lessons come back soon.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline).foregroundStyle(.orange)
            }
            Text("Mixing lessons is harder than studying one at a time, and that's the point: it trains you to tell ideas apart.")
                .font(.subheadline).foregroundStyle(.secondary)
            if !result.missed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remember this").font(.headline)
                    ForEach(result.missed) { q in
                        Text("\u{2022} \(q.explanation)").font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            AnswerReviewList(answers: result.answers)
            Button(action: onDone) {
                Text("Done").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.mint)
            .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Session complete
//
// The end of a session is where a learner decides whether to come back. It shows what
// was earned, what to remember, and when the next review is, with streak milestones
// (Duolingo found a milestone celebration lifts 7-day retention).

struct SessionCompleteView: View {
    let lesson: Lesson
    let result: LessonQuizResult
    let xpEarned: Int
    let onDone: () -> Void

    @EnvironmentObject var store: LearningStore
    @ObservedObject private var mastery = MasteryStore.shared
    @AppStorage(DailyTarget.minutesKey) private var minutes = 5

    static let milestones: Set<Int> = [3, 7, 14, 30, 50, 100, 200, 365]

    var body: some View {
        let target = DailyTarget.lessons(forMinutes: minutes)
        let streak = store.currentStreak
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(result.score) of \(result.total)").font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text(headline).font(.title3)
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 12) {
                stat("+\(xpEarned)", "XP", "bolt.fill", .yellow)
                stat("\(streak)", streak == 1 ? "day streak" : "day streak", "flame.fill", .orange)
                stat(mastery.level(lesson.id).rawValue, "this lesson", "brain.head.profile", .mint)
            }

            if Self.milestones.contains(streak) && store.practicedToday {
                Label("\(streak)-day streak! You're building a real habit.", systemImage: "flame.circle.fill")
                    .font(.headline).foregroundStyle(.orange)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Label(store.lessonsToday >= target ? "Today's target done (\(store.lessonsToday) of \(target))."
                  : "\(store.lessonsToday) of \(target) lessons today. One more keeps you on track.",
                  systemImage: "target")
                .font(.subheadline)

            if let card = SM2Engine.shared.card(for: lesson.id) {
                Label("You'll review this again \(card.daysUntilDue == 0 ? "later today" : "in \(card.daysUntilDue) \(card.daysUntilDue == 1 ? "day" : "days")"), right before you'd start to forget it.",
                      systemImage: "calendar.badge.clock")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if result.luckyGuesses > 0 || result.confidentMisses > 0 {
                Label(confidenceNote, systemImage: "gauge.with.needle")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            if !result.missed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remember this").font(.headline)
                    ForEach(result.missed) { q in
                        Text("\u{2022} \(q.explanation)").font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            AnswerReviewList(answers: result.answers)

            Button(action: onDone) {
                Text("Continue").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.mint)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var confidenceNote: String {
        var parts: [String] = []
        if result.luckyGuesses > 0 { parts.append("\(result.luckyGuesses) right answer\(result.luckyGuesses == 1 ? " was a guess" : "s were guesses")") }
        if result.confidentMisses > 0 { parts.append("\(result.confidentMisses) wrong answer\(result.confidentMisses == 1 ? " you were" : "s you were") sure about") }
        return parts.joined(separator: " and ") + ". The review schedule takes that into account."
    }

    private var headline: String {
        switch result.score * 5 / max(result.total, 1) {
        case 5: return "Perfect. This one is locked in."
        case 4: return "Strong recall. One detail to tighten up."
        case 3: return "Getting there. A review soon will make it stick."
        default: return "Good effort. It comes back tomorrow so you can try again."
        }
    }

    private func stat(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Prompt makeovers (AI Skills)

/// Pick the best rewrite of a weak prompt, then see why. Practising the judgment, not
/// just reading about it.
struct PromptMakeoverView: View {
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0
    @EnvironmentObject var store: LearningStore
    private let items = PromptMakeovers.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if items.indices.contains(index) {
                    let item = items[index]
                    Text("\(index + 1) of \(items.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
                    Text("Goal: \(item.goal)").font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weak prompt").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(item.weak).font(.system(.body, design: .monospaced))
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("Which rewrite works best?").font(.title3.bold())
                    ForEach(item.options.indices, id: \.self) { i in
                        Button { choose(i, item) } label: {
                            HStack(alignment: .firstTextBaseline) {
                                Text(item.options[i]).font(.system(.callout, design: .monospaced)).multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                if picked != nil && i == item.best { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                                else if picked == i { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                            }
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(picked == nil ? SprintPalette.card : (i == item.best ? Color.green.opacity(0.15) : (picked == i ? Color.red.opacity(0.12) : SprintPalette.card)),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(picked != nil)
                    }
                    if picked != nil {
                        Text(item.why).foregroundStyle(.secondary)
                        Button(index + 1 < items.count ? "Next" : "Finish") { picked = nil; index += 1 }
                            .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                } else {
                    Text("\(score) of \(items.count) best picks").font(.largeTitle.bold())
                    Text("Good prompts say what you want, who it's for and what good looks like, keep private details out, and leave the important checking to you.")
                        .foregroundStyle(.secondary)
                    Button("Practice again") { index = 0; score = 0; picked = nil }.buttonStyle(.borderedProminent)
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle("Prompt makeovers")
        .modifier(SprintTheme())
    }

    private func choose(_ i: Int, _ item: PromptMakeover) {
        picked = i
        if i == item.best { score += 1 }
        if index + 1 == items.count { store.recordPractice() }
        HapticManager.shared.notification(i == item.best ? .success : .warning)
        AccessibilityNotification.Announcement(i == item.best ? "Best choice" : "Not the best choice").post()
    }
}
