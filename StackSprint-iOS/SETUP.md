# StackSprint for iPhone & iPad

## Open in Xcode

1. Unzip the download. Open **StackSprint.xcodeproj** (do not drag the whole folder into another project).
2. Select the **StackSprint** scheme and an iPhone or iPad simulator. Press Run.
3. For your own device, open Signing & Capabilities, choose your Apple team, and replace `com.example.StackSprint` with your unique bundle identifier. Let Xcode manage signing.

Requires Xcode with an iOS 17+ SDK. Verified by compiling with Xcode 26.6 / iOS Simulator 26.5. No third-party Swift packages to install. Guest learning works before configuring a server.

## What is included

- Native SwiftUI tabs: Learn, Studio, Together, Account, adaptive to iPhone and iPad.
- 36 native cards: web development, Python, cybersecurity; 50 web/security quiz questions.
- Native keyboard transcription practice, local draft recovery, CSV flashcard export through Files, and native sharing.
- Existing web game studio bundled in WKWebView, retaining 60 code/design missions and Python remix exercises. It is intentionally not a native game-engine rewrite.
- Supabase email/password signup and login, Keychain session storage, token refresh, logout, account deletion, and manual native completion sync.
- SQL backend with row-level isolation; no service-role key ships in the app.

## Configure the backend

1. Create a Supabase project under your account. This package does **not** create, deploy, or pay for a hosted project.
2. Open its SQL Editor and run `backend/schema.sql` once on the new project. The script creates the progress table, access policies, and the account-deletion RPC.
3. In `StackSprint/BackendConfig.json`, replace the URL and public publishable key using your project's API settings. Use only a publishable key (or legacy **anon** key), **never** a secret/service-role key. Keep the URL without a trailing slash.
4. Enable email/password authentication. Keep email confirmation on. Configure a real Site URL for the confirmation landing page. Users confirm in their email browser and then return to the app to sign in; this starter does not consume auth deep links.
5. Configure SMTP, rate limits, and production auth controls before inviting real users. The bundled app does not include a password-recovery UI yet; add and test recovery before public launch.
6. Run the app, create two test accounts, confirm their emails, and sign in. Complete different native lessons and use **Account → Sync native lesson progress**. Each account must see only its own completions.

The REST API is supplied by Supabase; you do not run SQL inside Xcode. `Backend.swift` calls Auth and REST endpoints over HTTPS.

### API contract

- POST `/auth/v1/signup`: create email/password account.
- POST `/auth/v1/token?grant_type=password`: sign in.
- POST `/auth/v1/token?grant_type=refresh_token`: renew session.
- POST `/auth/v1/logout`: invalidate the signed-in session.
- GET `/rest/v1/progress?select=user_id,lesson_id`: read own completions, filtered by RLS.
- POST `/rest/v1/progress?on_conflict=user_id,lesson_id`: insert new completions; ignore duplicates.
- POST `/rest/v1/rpc/delete_my_account`: remove the authenticated account and cascade-delete its progress.

## Data and privacy

Guest and account progress are separate. Sync is manual and merges completed lesson IDs; it does not sync partial drafts, quiz attempts, or the embedded studio. No contacts are collected. Drafts and web studio progress remain on the device when signing out. Account deletion removes the authenticated account and cloud completions; local studio data remains until app data is cleared. Never enter secrets into lesson editors.

Completion records are learner-controlled practice records, not verified credentials or secure leaderboard scores. Backend policies isolate users but intentionally allow a learner to mark their own progress.

## Execution limits

Native flashcard typing checks are transcription checks, not a native Python compiler. The bundled studio supplies real JavaScript and Python exercises. Python downloads Pyodide from jsDelivr and requires internet. Web runtime behavior, download links, and sharing vary in WKWebView and require device testing; use native flashcard export and Together sharing for supported iOS flows. Local HTML resources are bundled; no hosted web URL is required to start.

## Before App Store submission

This is a buildable development package, not a submitted or production-certified app. Add your app icon and branding assets, production privacy policy/support URL, privacy manifest declarations appropriate to your final SDK/API use, password recovery, accessibility/device QA, App Store privacy disclosures, and signing. Test email delivery, session expiry, offline recovery, account deletion, and RLS with real Supabase accounts. Real friend connections, chat, push notifications, crosswords, and a unified web/native sync model are not implemented.

## Verification

Simulator compilation completed successfully. Native curriculum IDs/counts and quiz answer bounds can be checked using `node tests/package.test.cjs`. Backend policy tests are in `backend/test-local.sql`; run them only against a disposable PostgreSQL database (they create mock Supabase auth objects and roles). Hosted auth and device interaction still require end-to-end testing with your project credentials.

Official references: [Supabase password authentication](https://supabase.com/docs/guides/auth/passwords), [Supabase row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security), [SwiftUI](https://developer.apple.com/documentation/swiftui).

Python course topic attribution: [Asabeneh Yetayeh, 30 Days of Python, Day 2](https://github.com/Asabeneh/30-Days-Of-Python/blob/master/02_Day_Variables_builtin_functions/02_variables_builtin_functions.md). StackSprint exercises use original wording and Python 3 corrections.
