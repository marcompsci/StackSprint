# StackSprint — Apple compliance report

Audit date: November 12, 2026 · Branch: `studio-split-preview` · Auditor: Claude (automated audit + code fixes)

Sources: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), Apple's [upcoming requirements](https://developer.apple.com/news/upcoming-requirements/) (Xcode 26 SDK minimum since April 28, 2026; age-rating questions due January 31, 2026; Game Center entitlement requirement), and Apple's October 16, 2026 guideline update (1.2, new 2.5.19, section 5). Apple approval is never guaranteed by this report.

## 1. Architecture summary

| Area | What the code actually does |
|---|---|
| App | Native SwiftUI, one app target `phoronomicstudios.com.StackSprint`, team X6LZQ3FS36, automatic signing. iOS/iPadOS **26.5+**, device families iPhone, iPad and **visionOS** (`TARGETED_DEVICE_FAMILY = 1,2,7`). Version 1.0 (1). |
| Targets | App, unit tests (Swift Testing), UI tests. **No widget, watch or Live Activity extension target exists**, even though `WidgetSupport.swift`, `WatchCompanion.swift` and `StudyLiveActivity.swift` contain scaffolding. |
| Web runtime | Bundled HTML/CSS/JS "Full Studio" in a `WKWebView`; Studio previews and checks run learner code in sandboxed, non-persistent web views with a CSP that blocks network access. |
| Python | Pyodide 314.0.7 downloaded from jsDelivr the first time a learner runs Python; code runs on device in a web worker with a timeout. |
| AI | Apple Foundation Models (on-device) for Bite the tutor, conversations and generated lessons, with availability fallbacks. No cloud AI. |
| Accounts | Sign in with Apple (identity kept on device). Optional Supabase email accounts, **off** (placeholder config); when enabled: RLS-protected `progress` table and a `delete_my_account()` RPC. GitHub/Google OAuth code present but **hidden** (no token-exchange server). |
| Multiplayer | Game Center real-time race (scores only; names come from Game Center). No chat, no public UGC feed. |
| Payments | StoreKit 2 auto-renewing subscriptions `com.stacksprint.pro.monthly` / `.yearly`; unlocks Go, Rust and Interview Prep tracks (32 lessons) and Pro season collectibles. |
| Sync | CloudKit sync code exists but is disabled (`SSCloudKitEnabled` not set). |
| Notifications | Local notifications only. |
| Tests | 7 unit-test suites, 40 tests (curriculum, store, adaptive engine, challenges, premium, **compliance**, **code editing**); 4 Node web-runtime tests; 10 Studio missions verified against reference solutions in headless Chromium. Before this audit the unit-test target had no `TEST_HOST`/`BUNDLE_LOADER` and could not link; fixed. |

## 2. Findings

Severity: BLOCKER (would very likely cause rejection), HIGH, MEDIUM, LOW.

| # | Guideline | File(s) | Sev. | Concern | Remediation | Done | Verified by |
|---|---|---|---|---|---|---|---|
| 1 | 2.1, 2.3.1 | `SocialAuth.swift`, `SocialViews.swift`, `StackSprintApp.swift` | BLOCKER | With empty client IDs, "Continue with GitHub/Google" faked a successful login, an invented GitHub profile and 3 fake repos, and fake "Demo" commits. | Removed simulation. Providers show only when a client ID **and** a token-exchange backend exist. Leftover demo identities are cleared at launch. | Yes | `ComplianceTests.simulatedSignInIsOff`; gate check "No simulated sign-in" |
| 2 | 5.1.1(i) | — (app had none); `AppStoreScreenshots.swift` | BLOCKER | No privacy policy in the app; the listed URL `stacksprint.app/privacy` does not resolve. | Added in-app `PrivacyPolicyView` (Account, paywall). Hostable copy in `docs/privacy-policy.md`. Dead URLs cleared so they can't be pasted into App Store Connect. | Partly | Gate checks; **manual:** host the policy and enter its URL in App Store Connect |
| 3 | 2.3.1, 2.3 | `Leaderboard.swift`, `LeaderboardV2.swift`, `AnalyticsDashboard.swift` | HIGH | "Global" and "Friends" boards presented invented people ("Alex C.", "xX_dev_Xx") as real players; fabricated "Top 5%" ranks; share text claimed a rank. | Boards now show "Pacer 1…15" with a visible "computer-set, not real players" disclosure; fake Friends tab and rank-up banner removed; share text states XP only. | Yes | `ComplianceTests.pacersAreLabelledNotInventedPeople`; gate |
| 4 | 3.1.2(a)(c) | `PremiumStore.swift` | HIGH | Paywall had no Terms of Use or Privacy Policy links; advertised "unlimited AI chats" (AI is unlimited for everyone), a "Pro crown" that doesn't exist and "2× XP weekends" (free for everyone); infinite spinner when products fail to load; hard-coded billing period. | Honest feature list; Terms (Apple standard EULA) and Privacy links; full renewal disclosure; period from `product.subscription`; "not available / Try again" state. | Yes | Gate payment checks |
| 5 | 3.1.1, 2.3.1 | `SeasonPass.swift` | HIGH | Pro and free season rewards promised themes, XP multipliers, extra AI quota and leaderboard crowns, but claiming only marked them "claimed". | Rewards renamed and described as collectibles; no functional promises remain. | Yes | `ComplianceTests.seasonRewardsDoNotPromiseFeatures` |
| 6 | Game Center entitlement requirement; 4.8 | `project.pbxproj`, `StackSprint.entitlements` | HIGH | Entitlements file was never attached to the target, so Sign in with Apple could not work and GameKit shipped without the Game Center entitlement. File also requested unused CloudKit, push and App Groups. | Attached via `CODE_SIGN_ENTITLEMENTS`; trimmed to Sign in with Apple + Game Center. | Yes | Gate; **manual:** confirm signing on device/archive |
| 7 | 5.1.1(iii), 2.5.4 | `Info.plist` | HIGH | Camera, microphone and tracking purpose strings for features the app doesn't have (tracking string invites an ATT question); `remote-notification` background mode with no push; `com.example` URL name. | Removed; URL type renamed to the bundle ID. | Yes | Gate Info.plist checks |
| 8 | 2.1 | `StackSprintApp.swift`, `CloudKitSync.swift` | MEDIUM | "iCloud sync is coming soon" section, a disabled email/password form, and developer setup text ("configure BackendConfig.json…") shown to users. | Hidden unless the feature is configured; plain copy instead. | Yes | Code review |
| 9 | 2.1 | `AppIconManager.swift` | MEDIUM | Pro/season app-icon picker offered icons whose assets don't exist (switching would fail). | Picker hides until `CFBundleAlternateIcons` ship. | Yes | Code review |
| 10 | 1.2 / input validation | `FriendChallenge.swift` | MEDIUM | Challenge deep links displayed any sender name (links, line breaks, unlimited length) and accepted unbounded IDs/scores. | IDs limited and character-checked, score clamped, name cleaned (24 chars, no links/control characters). | Yes | `ComplianceTests.challengeNamesAreCleaned`, `.challengeLinksAreBounded` |
| 11 | 5.1.2 | `Web/index.html` | MEDIUM | Google Fonts requests sent every user's IP to Google. | Same fonts bundled locally (SIL OFL, licences included). | Yes | Headless check: 0 external requests, fonts load |
| 12 | 2.3.1 | `AppStoreScreenshots.swift` | MEDIUM | Draft App Store description claimed widgets, iCloud sync, a global leaderboard and unlimited AI. | Rewritten to match shipped features. | Yes | Code review |
| 13 | 2.5.2 | `Web/python-runtime.js` | MEDIUM (accepted) | Downloads the Pyodide interpreter at runtime. 2.5.2 allows educational apps that let students test executable code to download code used only for that purpose. | Kept; explained in review notes and privacy policy. | N/A | Review notes |
| 14 | 2.1, 2.5 | Project settings | MEDIUM (decision) | iPad and visionOS are enabled. App Review may test on either; visionOS needs its own testing and screenshots. | Not changed. Your call: test both, or limit `TARGETED_DEVICE_FAMILY`. | No | Gate warning |
| 15 | 1.5, 2.1 | `LegalViews.swift` | HIGH (manual) | No support contact. | Support row appears once `LegalLinks.supportEmail` is set; `--release` fails while it's empty. | Partly | Gate `--release` |
| 16 | Age ratings (Jan 31, 2026) | App Store Connect | HIGH (manual) | New questionnaire covers AI assistants/chatbots and in-app controls. | Answer in App Store Connect (Bite tutor is an AI assistant; Game Center races). | No | Manual |
| 17 | 2.1 | `WidgetSupport.swift`, `StudyLiveActivity.swift` | LOW | Widget/Live Activity code with no extension target; `NSSupportsLiveActivities` set. Live Activities can't appear without an extension. | Left as is (no user-visible promise remains in-app). Add an extension or remove the key before advertising them. | No | Code review |
| 18 | Secrets | Repo | — | No keys, tokens, private keys or service-role keys found; `BackendConfig.json` holds placeholders only; tokens use the Keychain. | CI scans full history with gitleaks on every push. | Yes | Gate + CI |
| 19 | 5.1.1(v) | `Backend.swift`, `backend/schema.sql` | — | When cloud accounts are enabled, in-app deletion removes the auth user and cascades progress; RLS limits rows to their owner. | Already compliant. | Yes | Schema review |
| 20 | 3.1.2 restore | `PremiumStore.swift` | — | Restore Purchases present; `Transaction.updates` observed; unverified transactions ignored. | Already compliant. | Yes | Gate |

## 3. Guideline coverage

- **1.1 Objectionable content:** educational content only; AI output is on-device and topic-limited by system instructions. No issue found.
- **1.2 UGC:** no public feed or chat. Game Center races exchange scores; Game Center handles names and reporting. Challenge links are shared person-to-person and are now sanitised. 2026 NCII/moderation additions don't apply (no image or user-content sharing).
- **1.3 Kids:** not in the Kids category; privacy policy says not directed at under-13s. Don't select the Kids category without a review.
- **2.1 Completeness:** fake and placeholder features removed (findings 1, 3, 5, 8, 9). Products must exist in App Store Connect before review.
- **2.2 Beta testing:** TestFlight build must be the same app; no hidden test-only switches found.
- **2.3 Metadata:** see finding 12; use `docs/app-review-notes.md` and `docs/external-tester-guide.md`.
- **2.5 Software requirements:** public APIs only; Xcode 26 SDK required (met); 2.5.2 see finding 13; new 2.5.19 (bait-and-switch): ship what review sees.
- **3.1 Payments:** StoreKit only; no external links to purchase. See findings 4, 5.
- **4.2 Minimum functionality:** rich native app; passes.
- **4.7:** Full Studio runs bundled HTML5 mini-projects written by the learner; no third-party mini-app store.
- **4.8 Login services:** Sign in with Apple offered; third-party logins hidden.
- **5.1 Privacy:** findings 2, 7, 11; data inventory in `docs/privacy-security-audit.md`.
- **5.2 IP:** fonts OFL; Pyodide MPL 2.0; Python lesson cites its inspiration. No issue found.
- **5.4 VPN:** not applicable.

## 4. Verification run

| Check | Result |
|---|---|
| `scripts/compliance-check.sh` | 0 failed, 5 warnings (support email, privacy URL, support URL, iPad, visionOS) |
| `scripts/compliance-check.sh --release` | **4 failed** until the support email, privacy URL and support URL are set |
| Node web tests (4) | Pass |
| Studio mission checks vs reference solutions (headless Chromium) | 10/10 solutions pass all checks; starters fail as expected |
| Bundled fonts / external requests | Fonts load; 0 third-party requests on page load |
| GitHub Actions run 43322718431 (macos-26, Xcode 26.6, iOS 26.5 SDK) | Release build **succeeded**; static analysis **succeeded**; unit tests **40 tests in 7 suites passed** on an iPhone 17 Pro simulator (iOS 26.5) |
| Full-history secret scan (gitleaks 8.24.3) | 47 commits scanned, no leaks |
| On-device build | Not run this session: another Claude session was installing a different app on the same iPhone. Run in Xcode before archiving. |

## 5. Remaining manual actions

1. Set `LegalLinks.supportEmail` and host `docs/privacy-policy.md`; put the URLs in `AppStoreCopy` and App Store Connect.
2. Decide on iPad and visionOS support.
3. App Store Connect: create the two subscriptions in a group, add review screenshots, enable Game Center, answer App Privacy (see privacy audit) and the age-rating questions.
4. Bump `CURRENT_PROJECT_VERSION`, archive the Release build in Xcode, and Validate App in the Organizer.
5. Build on a real iPhone once to confirm Sign in with Apple and Game Center signing work with the newly attached entitlements.

## 6. Release-readiness result

**FAIL** — not because the code is broken, but because three submission requirements are unresolved: no support contact, no hosted privacy policy URL, and the subscriptions don't exist in App Store Connect yet. Once those are set and `scripts/compliance-check.sh --release` passes, the expected result is **CONDITIONAL** (manual Apple steps remain). It is never PASS merely because it compiles.
