import Combine
import SwiftUI

// MARK: - Friend Challenge Model

struct FriendChallenge: Identifiable, Codable {
    let id: UUID
    let lessonIDs: [String]
    let creatorScore: Int
    let creatorName: String
    let createdAt: Date
}

// MARK: - Friend Challenge Store

@MainActor final class FriendChallengeStore: ObservableObject {
    static let shared = FriendChallengeStore()

    @Published var incomingChallenge: FriendChallenge?
    @Published var activeChallenge: FriendChallenge?
    @Published var activeLessons: [Lesson] = []
    @Published var state: ChallengeState = .idle
    @Published var myScore = 0
    @Published var currentIndex = 0
    @Published var timeRemaining = 60
    @Published var challengeFinished = false

    enum ChallengeState { case idle, racing, finished }

    static let questionsPerChallenge = 5

    private var timerTask: Task<Void, Never>?

    // MARK: Create challenge URL from a played quiz

    func createChallengeURL(lessons: [Lesson], myScore: Int, creatorName: String) -> URL? {
        let picked = Array(lessons.shuffled().prefix(Self.questionsPerChallenge))
        let ids = picked.map(\.id).joined(separator: ",")
        var comps = URLComponents()
        comps.scheme = "stacksprint"
        comps.host = "challenge"
        comps.queryItems = [
            URLQueryItem(name: "ids",   value: ids),
            URLQueryItem(name: "score", value: "\(myScore)"),
            URLQueryItem(name: "from",  value: creatorName),
        ]
        return comps.url
    }

    // MARK: Parse incoming deep link

    func parseURL(_ url: URL) {
        guard url.host == "challenge",
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idsVal   = comps.queryItems?.first(where: { $0.name == "ids" })?.value,
              let scoreVal = comps.queryItems?.first(where: { $0.name == "score" })?.value,
              let fromVal  = comps.queryItems?.first(where: { $0.name == "from" })?.value,
              let score = Int(scoreVal)
        else { return }

        let ids = idsVal.split(separator: ",").map(String.init)
        incomingChallenge = FriendChallenge(
            id: UUID(), lessonIDs: ids,
            creatorScore: score,
            creatorName: fromVal,
            createdAt: .now
        )
    }

    // MARK: Start a challenge race

    func startRace(challenge: FriendChallenge, allLessons: [Lesson]) {
        let resolved = challenge.lessonIDs.compactMap { id in allLessons.first { $0.id == id } }
        guard !resolved.isEmpty else { return }
        activeChallenge = challenge
        activeLessons   = resolved
        myScore         = 0
        currentIndex    = 0
        timeRemaining   = 60
        challengeFinished = false
        state = .racing
        incomingChallenge = nil
        startTimer()
    }

    func answerCorrect() { myScore += 1; advance() }
    func answerWrong()   { advance() }

    private func advance() {
        currentIndex += 1
        if currentIndex >= activeLessons.count { finish() }
    }

    private func finish() {
        timerTask?.cancel()
        state = .finished
        challengeFinished = true
        HapticManager.shared.notification(myScore >= (activeChallenge?.creatorScore ?? 0) ? .success : .warning)
    }

    func reset() {
        timerTask?.cancel()
        state = .idle
        incomingChallenge = nil
        activeChallenge = nil
        activeLessons = []
        myScore = 0
        currentIndex = 0
        timeRemaining = 60
        challengeFinished = false
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, self.timeRemaining > 0 && self.state == .racing {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self.timeRemaining -= 1
                if self.timeRemaining == 0 { await MainActor.run { self.finish() } }
            }
        }
    }
}

// MARK: - Create Challenge View

struct CreateChallengeView: View {
    @EnvironmentObject var store: LearningStore
    @StateObject private var challengeStore = FriendChallengeStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var quizIndex = 0
    @State private var myScore = 0
    @State private var phase: Phase = .quiz
    @State private var revealed = false
    @AppStorage("username") private var username = "You"

    enum Phase { case quiz, share }

    private var questions: [Lesson] {
        Array((store.curriculum?.lessons ?? []).shuffled().prefix(FriendChallengeStore.questionsPerChallenge))
    }
    @State private var sessionQuestions: [Lesson] = []

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .quiz: quizPhase
                case .share: sharePhase
                }
            }
            .navigationTitle("Friend Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .onAppear { if sessionQuestions.isEmpty { sessionQuestions = questions } }
    }

    @ViewBuilder private var quizPhase: some View {
        if sessionQuestions.indices.contains(quizIndex) {
            let lesson = sessionQuestions[quizIndex]
            VStack(spacing: 22) {
                Text("Q \(quizIndex + 1) of \(FriendChallengeStore.questionsPerChallenge)")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                VStack(spacing: 14) {
                    Text(lesson.term).font(.title2.bold()).multilineTextAlignment(.center)
                    Text(lesson.clue).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if revealed {
                        Text(lesson.definition).font(.subheadline).padding(14)
                            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
                if !revealed {
                    Button("Reveal") { revealed = true }.buttonStyle(.borderedProminent).tint(.blue)
                } else {
                    HStack(spacing: 16) {
                        Button("Got it ✓") {
                            myScore += 1; nextQuestion()
                        }.buttonStyle(.borderedProminent).tint(.mint).frame(maxWidth: .infinity)
                        Button("Missed ✗") {
                            nextQuestion()
                        }.buttonStyle(.borderedProminent).tint(.orange.opacity(0.8)).frame(maxWidth: .infinity)
                    }.padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 24)
        }
    }

    private func nextQuestion() {
        revealed = false
        quizIndex += 1
        if quizIndex >= sessionQuestions.count { phase = .share }
    }

    private var sharePhase: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "person.2.wave.2.fill").font(.system(size: 56)).foregroundStyle(.blue)
            VStack(spacing: 8) {
                Text("You scored \(myScore)/\(FriendChallengeStore.questionsPerChallenge)!")
                    .font(.title.bold())
                Text("Share this challenge so a friend can beat your score.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if let url = challengeStore.createChallengeURL(
                lessons: sessionQuestions,
                myScore: myScore,
                creatorName: username
            ) {
                ShareLink(item: url, message: Text("Can you beat my score of \(myScore)/\(FriendChallengeStore.questionsPerChallenge)? Try this StackSprint challenge!")) {
                    Label("Share Challenge Link", systemImage: "square.and.arrow.up")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent).tint(.blue)
                .padding(.horizontal, 32)
            }
            Button("Done") { dismiss() }.foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Accept Challenge Sheet

struct AcceptChallengeSheet: View {
    let challenge: FriendChallenge
    @EnvironmentObject var store: LearningStore
    @ObservedObject var challengeStore = FriendChallengeStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if challengeStore.state == .racing || challengeStore.state == .finished {
                ChallengeRaceView()
            } else {
                acceptPromptView
            }
        }
        .modifier(SprintTheme())
    }

    private var acceptPromptView: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "flame.fill").font(.system(size: 60)).foregroundStyle(.orange)
            VStack(spacing: 8) {
                Text("\(challenge.creatorName) challenged you!").font(.title2.bold())
                Text("Can you beat \(challenge.creatorScore)/\(FriendChallengeStore.questionsPerChallenge)?")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("60 seconds · \(challenge.lessonIDs.count) questions").font(.caption).foregroundStyle(.secondary)
            }
            Button {
                HapticManager.shared.impact()
                challengeStore.startRace(challenge: challenge, allLessons: store.curriculum?.lessons ?? [])
            } label: {
                Label("Accept Challenge", systemImage: "bolt.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent).tint(.orange).padding(.horizontal, 32)
            Button("Decline") { challengeStore.reset(); dismiss() }.foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Challenge Race View

struct ChallengeRaceView: View {
    @ObservedObject var cs = FriendChallengeStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if cs.state == .finished {
                finishedView
            } else if cs.activeLessons.indices.contains(cs.currentIndex) {
                racingView(lesson: cs.activeLessons[cs.currentIndex])
            } else {
                ProgressView()
            }
        }
    }

    private func racingView(lesson: Lesson) -> some View {
        VStack(spacing: 0) {
            // Timer + score bar
            HStack {
                Text("⏱ \(cs.timeRemaining)s")
                    .font(.headline.bold())
                    .foregroundStyle(cs.timeRemaining <= 10 ? .red : .primary)
                Spacer()
                Text("Score: \(cs.myScore)")
                    .font(.headline.bold()).foregroundStyle(.mint)
                Spacer()
                Text("vs \(cs.activeChallenge?.creatorScore ?? 0)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20).padding(.top, 16)
            .background(SprintPalette.card)

            Spacer()
            VStack(spacing: 16) {
                Text("Q \(cs.currentIndex + 1)/\(cs.activeLessons.count)")
                    .font(.caption.bold()).foregroundStyle(.secondary)
                Text(lesson.term).font(.title2.bold()).multilineTextAlignment(.center)
                Text(lesson.clue).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            Spacer()
            HStack(spacing: 14) {
                Button("Know it ✓") {
                    HapticManager.shared.impact()
                    cs.answerCorrect()
                }.buttonStyle(.borderedProminent).tint(.mint).font(.headline).frame(maxWidth: .infinity)
                Button("Skip ✗") {
                    HapticManager.shared.impact()
                    cs.answerWrong()
                }.buttonStyle(.borderedProminent).tint(.orange.opacity(0.8)).font(.headline).frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    private var finishedView: some View {
        let target = cs.activeChallenge?.creatorScore ?? 0
        let won = cs.myScore >= target
        return VStack(spacing: 24) {
            Spacer()
            Image(systemName: won ? "trophy.fill" : "star.fill")
                .font(.system(size: 70)).foregroundStyle(won ? .yellow : .orange)
            VStack(spacing: 8) {
                Text(won ? "You beat the challenge!" : "Close call!").font(.largeTitle.bold())
                Text("Your score: \(cs.myScore) · Target: \(target)")
                    .font(.subheadline).foregroundStyle(.secondary)
                if won {
                    Text("Challenge \(cs.activeChallenge?.creatorName ?? "your friend") to a rematch!")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("Done") { cs.reset(); dismiss() }
                .buttonStyle(.borderedProminent).tint(won ? .yellow : .mint).font(.headline)
            Spacer()
        }
        .padding(32)
    }
}
