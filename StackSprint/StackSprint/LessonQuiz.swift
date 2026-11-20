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
}

struct LessonQuizView: View {
    let lesson: Lesson
    let questions: [LessonQuizQuestion]
    /// XP the lesson itself earned this visit (10 when it was finished for the first time).
    let lessonXP: Int
    let onFinish: (LessonQuizResult) -> Void

    @EnvironmentObject var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0
    @State private var selected: Int?
    @State private var score = 0
    @State private var missed: [LessonQuizQuestion] = []
    @State private var quizXP = 0
    @State private var finished: LessonQuizResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let finished {
                        SessionCompleteView(lesson: lesson, result: finished, xpEarned: lessonXP + quizXP) { dismiss() }
                    } else if questions.indices.contains(index) {
                        question(questions[index])
                    }
                }
                .padding(24)
                .frame(maxWidth: 700)
            }
            .navigationTitle(finished == nil ? "Lesson quiz" : "Lesson complete")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar {
                if finished == nil {
                    ToolbarItem(placement: .cancellationAction) { Button("Later") { dismiss() } }
                }
            }
        }
        .interactiveDismissDisabled(finished == nil && index > 0)
    }

    @ViewBuilder
    private func question(_ q: LessonQuizQuestion) -> some View {
        HStack {
            Text("\(index + 1) of \(questions.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
            Spacer()
            Text(q.kind.label).font(.caption.bold()).foregroundStyle(.mint)
        }
        ProgressView(value: Double(index), total: Double(questions.count)).tint(.mint)
        Text(q.prompt).font(.title3.bold()).fixedSize(horizontal: false, vertical: true)
        ForEach(q.choices.indices, id: \.self) { i in
            Button { answer(q, i) } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(q.choices[i]).multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if selected != nil && i == q.answer { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    else if selected == i { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fill(i, q), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.secondary.opacity(0.2)))
            }
            .buttonStyle(.plain)
            .disabled(selected != nil)
            .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
            .accessibilityLabel(label(i, q))
        }
        if let selected {
            Text(selected == q.answer ? "Right." : "The answer is \(q.choices[q.answer]).").font(.headline)
            Text(q.explanation).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button(index + 1 < questions.count ? "Next question" : "See results") { next() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func answer(_ q: LessonQuizQuestion, _ choice: Int) {
        selected = choice
        if choice == q.answer {
            score += 1
            // Same rule as every quiz: 5 XP per question answered right, once a day.
            if store.recordDailyRecall(q.id) { quizXP += 5 }
            HapticManager.shared.notification(.success)
            AccessibilityNotification.Announcement("Correct").post()
        } else {
            missed.append(q)
            HapticManager.shared.notification(.warning)
            AccessibilityNotification.Announcement("Not quite. The answer is \(q.choices[q.answer]).").post()
        }
    }

    private func next() {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.2)) {
            selected = nil
            index += 1
            if index >= questions.count {
                let result = LessonQuizResult(score: score, total: questions.count, missed: missed)
                finished = result
                onFinish(result)
            }
        }
    }

    private func fill(_ i: Int, _ q: LessonQuizQuestion) -> Color {
        guard let selected else { return SprintPalette.card }
        if i == q.answer { return .green.opacity(0.16) }
        if i == selected { return .red.opacity(0.14) }
        return SprintPalette.card
    }

    private func label(_ i: Int, _ q: LessonQuizQuestion) -> String {
        guard let selected else { return q.choices[i] }
        if i == q.answer { return "\(q.choices[i]), correct answer" }
        if i == selected { return "\(q.choices[i]), your answer, incorrect" }
        return q.choices[i]
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

            if !result.missed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remember this").font(.headline)
                    ForEach(result.missed) { q in
                        Text("\u{2022} \(q.explanation)").font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Button(action: onDone) {
                Text("Continue").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.mint)
            .keyboardShortcut(.defaultAction)
        }
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
