# Verification — September 22, 2026

- Xcode simulator build: passed using Xcode 26.6, iOS Simulator 26.5 SDK; arm64 and x86_64 built, no code signing required for compilation.
- Native package tests: passed; 36 unique lesson IDs, 50 quiz questions with valid answers, bundled web asset paths, placeholder-only backend config.
- Backend SQL executed on a disposable local PostgreSQL 17 database with mock Supabase auth roles and auth.uid(): passed own-user inserts, rejection of cross-user inserts, cross-user read isolation, anonymous access denial, self-account deletion, and cascading progress deletion.
- Temporary database server stopped after tests.
- Simulator launch smoke test was not completed: the fresh iPhone simulator remained in OS first-boot migration. The wait was canceled; successful compilation is not a claim of interactive runtime verification.

Not verified: hosted Supabase email delivery/auth integration, real-device signing, all WKWebView runtime flows, app-store submission, and accessibility across all devices. Local policy tests do not replace hosted end-to-end tests. No hosted backend was provisioned or deployed.
