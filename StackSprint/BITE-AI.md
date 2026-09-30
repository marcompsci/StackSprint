# Bite: on-device coding companion

The native SwiftUI app has a transparent pixel companion over its tabs. Tap it to open a question-and-answer sheet. The existing web app retains local tips and its keyboard reaction; browser JavaScript cannot call Apple's native AI frameworks. The embedded Studio hides its duplicate web pet in favor of the native assistant button.

## Included

- Foundation Models: a fresh `LanguageModelSession` per question on iOS 26+ when `SystemLanguageModel` is available. Questions are bounded to 1,600 characters, and matching bundled lesson definitions are included as reference. No cloud AI service or API key is used.
- Offline fallback: explicitly labeled lesson excerpts and practice tips. These are not generative AI.
- AVFoundation: user-triggered spoken answers, stopped when the sheet closes.
- SwiftUI and Canvas: accessible assistant controls and a transparent pixel avatar. The native layout follows the system keyboard safe area.
- Core ML: `BiteCoreMLClassifier` supplies a loader and prediction adapter for an optional custom hint classifier. **No trained model is included and the adapter is not currently used by chat.** A validated model is required before enabling this path; importing Core ML does not make it a language model.

## Custom Core ML contract

Train and evaluate a hint-topic classifier using appropriately licensed training data. Add `BiteHintClassifier.mlmodel` to the app target in Xcode. It must accept string feature `text` and return string feature `label`. The adapter loads the compiled `.mlmodelc` resource, enables available compute units, and returns nil when absent. Wire its validated labels to a lesson retrieval policy before shipping. Do not treat its labels as proof that learner code is correct.

## Limits and release checks

- Availability depends on hardware, OS, Apple Intelligence settings, model readiness and supported language/region. The assistant is optional; courses work without it.
- Each question is independent, with no chat memory or automatic access to the learner's current editor. Paste the relevant snippet explicitly. Input and answers are not persisted by this feature.
- AI suggestions are not executed and never unlock lessons or award XP. Validate suggestions with existing Studio checks.
- Simulator-target compilation and existing JavaScript/package checks passed. Actual model responses, speech, layout and keyboard behavior still require eligible iPhone/iPad testing. No claims of learning efficacy or App Store ranking have been validated.
- Before release, evaluate representative beginner questions, incorrect code, safety refusals, unavailable-model behavior, cancellation, accessibility and large text on real devices.

Apple references: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel and https://developer.apple.com/documentation/coreml/mlmodel
