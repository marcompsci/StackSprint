# StackSprint — privacy and security audit

Audit date: November 12, 2026. Applies to the current `studio-split-preview` build. Re-check whenever a network call, SDK, account feature or permission changes.

## Data inventory (what leaves the device)

"Collected" uses Apple's definition: transmitted off the device in a way the developer or its partners can access.

| Data | When | Sent to | Linked to user | Tracking | App Privacy answer |
|---|---|---|---|---|---|
| Nothing (default) | Guest use, Sign in with Apple, Studio, lessons, AI tutor | — | — | — | **Data Not Collected** while cloud accounts are off |
| Email address | Only if Supabase cloud accounts are turned on and the user creates one | Supabase (processor) | Yes | No | Contact Info → Email Address, App Functionality |
| User ID | Same | Supabase | Yes | No | Identifiers → User ID, App Functionality |
| Completed lesson IDs | Same, on Sync | Supabase | Yes | No | Usage Data → Product Interaction, App Functionality |
| IP address (incidental) | First Python run (Pyodide from jsDelivr) | jsDelivr CDN | No | No | Not "collected" by the developer; disclosed in the privacy policy |
| Game Center name, race score | Study Room race | Apple Game Center / the opponent | Handled by Apple | No | Covered by Apple |
| Purchases | Subscribing | Apple | Handled by Apple | No | Not collected by the developer |

On-device only (never sent): lesson progress, quiz scores, streaks, XP, season progress, Studio missions and free-build projects, code drafts, Sign in with Apple name/email/user ID, AI tutor prompts and responses (Foundation Models), local notification schedule.

**Action:** while `BackendConfig.json` holds placeholders, answer **Data Not Collected** in App Store Connect. When cloud accounts are enabled, change the answers to the three Supabase rows above **before** shipping that build.

## Privacy manifest (`StackSprint/PrivacyInfo.xcprivacy`)

| Item | Value | Status |
|---|---|---|
| `NSPrivacyTracking` | false | Correct |
| `NSPrivacyTrackingDomains` | empty | Correct |
| Collected data types | Email, Name, User ID, Other User Content (all non-tracking, App Functionality) | Over-declares for the current build (nothing is collected with accounts off). Over-declaring is allowed; keep it consistent with App Store Connect when accounts go live. Name and Other User Content can be removed if accounts never send them. |
| Required-reason API: UserDefaults | CA92.1 | Correct (used throughout) |
| Required-reason API: File timestamp | C617.1 | Declared but no use found; harmless |
| Third-party SDKs | None (no SPM/CocoaPods/npm dependencies) | No SDK manifests needed |

## Permissions and purpose strings

| Key | Before | After |
|---|---|---|
| `NSCameraUsageDescription` | "does not use the camera" | Removed (no camera API in code) |
| `NSMicrophoneUsageDescription` | "does not use the microphone" | Removed (speech is synthesis only, `AVSpeechSynthesizer`) |
| `NSUserTrackingUsageDescription` | present | Removed (no ATT, no tracking) |
| `UIBackgroundModes: remote-notification` | present | Removed (no push registration) |
| Notifications | runtime prompt | Local reminders only |

## Network transport

| Host | Purpose | TLS |
|---|---|---|
| `<project>.supabase.co` | Optional accounts/progress (off) | HTTPS only; `BackendConfig` rejects non-HTTPS by URL format |
| `cdn.jsdelivr.net` | Pyodide runtime | HTTPS |
| `api.github.com`, `github.com` | GitHub features (hidden) | HTTPS |
| Remote curriculum URL | Optional (empty) | Code enforces `https` scheme |

No App Transport Security exceptions exist. Learner-code web views use `nonPersistent` data stores and a CSP with `default-src 'none'`, so learner code cannot make network requests. Navigation away from the preview is cancelled.

`ITSAppUsesNonExemptEncryption = false` is correct: the app uses only HTTPS and Apple-provided cryptography. Answer export compliance as "exempt" (standard encryption only).

## Credentials and sessions

- No secrets in the repo or bundle (manual grep plus a CI gitleaks scan of every commit). `BackendConfig.json` may hold only a URL and the Supabase **publishable** key; the gate fails on anything else.
- Supabase session and GitHub token are stored in the Keychain (`Security` framework), not UserDefaults.
- GitHub/Google OAuth never hold a client secret in the app; both stay hidden until a server exchanges the code for a token.
- Sign in with Apple: identifier, name and email are stored locally in UserDefaults to label progress. Low sensitivity, but consider moving the user ID to the Keychain.

## Server-side authorization (Supabase, when enabled)

- `progress` has RLS enabled; `anon` has no access; `authenticated` can select/insert only rows where `auth.uid() = user_id`.
- `delete_my_account()` is `security definer` with an empty `search_path`, deletes only `auth.uid()`, and progress rows cascade. Granted to `authenticated` only.
- No update/delete policies exist on `progress` (not needed by the app).
- Recommended before enabling: run `backend/test-local.sql`, add rate limiting on sign-up in the Supabase dashboard, and enable email confirmation.

## Input validation and output handling

- Challenge deep links (`stacksprint://challenge`) now bound lesson IDs (max 5, `[A-Za-z0-9_-]`), clamp the score, and clean the sender name (no links, control characters or line breaks; max 24 characters).
- Learner HTML/CSS/JS runs only inside sandboxed web views; `</` is escaped when code is embedded in a page.
- AI output is rendered as text; no web content from the model is executed.

## Account deletion (5.1.1(v))

- Sign in with Apple: no server account exists; "Disconnect account" removes the local identity.
- Supabase accounts (when enabled): Account → Delete account → confirmation → server-side deletion of the user and all progress, then local session cleared.

## Open items

1. Host the privacy policy (`docs/privacy-policy.md`) at a public HTTPS URL and set a support contact.
2. Decide whether to trim the privacy manifest's collected types to match the shipped build.
3. Before enabling CloudKit: attach the iCloud entitlement, set `SSCloudKitEnabled`, and update this audit and the privacy policy.
