import AVFoundation
import Combine
import SwiftUI

// MARK: - Voice Manager

@MainActor final class VoiceManager: ObservableObject {
    static let shared = VoiceManager()

    @Published var isSpeaking = false
    @AppStorage("voice.rate") var rate: Double = 0.5

    private let synthesizer = AVSpeechSynthesizer()
    private var delegate: SynthDelegate?

    private init() {
        let d = SynthDelegate { [weak self] in
            Task { @MainActor in
                // A cancelled utterance reports in after the next one has started; ignore it then.
                guard let self, !self.synthesizer.isSpeaking else { return }
                self.isSpeaking = false
                self.releaseAudio()
            }
        }
        delegate = d
        synthesizer.delegate = d
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        // Read aloud was silent with the ring/silent switch off, because the app used the
        // default ambient audio session. Spoken-audio playback is heard, and other audio dips.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        let minRate = AVSpeechUtteranceMinimumSpeechRate
        let maxRate = AVSpeechUtteranceMaximumSpeechRate
        utterance.rate = minRate + Float(rate) * (maxRate - minRate)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        releaseAudio()
    }

    /// Lets music or podcasts the learner paused come back up.
    private func releaseAudio() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func toggle(_ text: String) { isSpeaking ? stop() : speak(text) }
}

private final class SynthDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish()
    }
}

// MARK: - Read Aloud Button

struct ReadAloudButton: View {
    @ObservedObject private var vm = VoiceManager.shared
    let text: String

    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            vm.toggle(text)
        } label: {
            Label(vm.isSpeaking ? "Stop" : "Read aloud",
                  systemImage: vm.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill")
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(vm.isSpeaking ? Color.orange.opacity(0.12) : SprintPalette.card,
                            in: Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(vm.isSpeaking ? .orange : .secondary)
        .accessibilityLabel(vm.isSpeaking ? "Stop reading" : "Read lesson aloud")
    }
}

// MARK: - Voice Speed Settings Section (embed in AccountView)

struct VoiceSpeedSection: View {
    @AppStorage("voice.rate") private var rate: Double = 0.5

    private var speedLabel: String {
        switch rate {
        case ..<0.3: return "Slow"
        case 0.3..<0.6: return "Normal"
        case 0.6..<0.8: return "Fast"
        default: return "Very fast"
        }
    }

    var body: some View {
        Section {
            HStack {
                Text("Reading speed")
                Spacer()
                Text(speedLabel).foregroundStyle(.secondary).font(.subheadline)
            }
            Slider(value: $rate, in: 0...1, step: 0.1)
                .tint(.mint)
        } header: {
            Label("Voice & Accessibility", systemImage: "speaker.wave.2.fill")
        } footer: {
            Text("Tap \u{201C}Read aloud\u{201D} on any lesson to hear it spoken aloud using your device\u{2019}s voice.")
        }
    }
}
