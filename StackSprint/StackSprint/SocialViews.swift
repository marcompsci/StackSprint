import SwiftUI

// MARK: - Sign-In Options (onboarding step 1)

struct SignInOptionsView: View {
    @EnvironmentObject var socialAuth: SocialAuthManager
    var onComplete: () -> Void

    var body: some View {
        if socialAuth.isSignedIn {
            signedInState
        } else {
            signInPrompt
        }
    }

    private var signInPrompt: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Save your streak.")
                .font(.system(.largeTitle, design: .rounded).bold())
            Text("Sign in once and your progress syncs to all your devices. Or tap below to continue as a guest — you can connect an account later.")
                .foregroundStyle(.secondary)

            VStack(spacing: 13) {
                ProviderButton(label: "Continue with Apple",
                               icon: "apple.logo",
                               style: .apple,
                               busy: socialAuth.busy) {
                    Task {
                        do { try await socialAuth.signInWithApple(); onComplete() }
                        catch { }
                    }
                }
                ProviderButton(label: "Continue with Google",
                               icon: "g.circle.fill",
                               style: .google,
                               busy: false) {
                    Task {
                        do { try await socialAuth.signInWithGoogle(); onComplete() }
                        catch { }
                    }
                }
                ProviderButton(label: "Continue with GitHub",
                               icon: "chevron.left.forwardslash.chevron.right",
                               style: .github,
                               busy: socialAuth.busy && socialAuth.authProvider == .none) {
                    Task {
                        do { try await socialAuth.signInWithGitHub(); onComplete() }
                        catch { }
                    }
                }
            }

            if socialAuth.busy {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Connecting…").font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)
            }

            HStack { Spacer()
                Button("Continue as guest →") { onComplete() }
                    .font(.subheadline).foregroundStyle(.secondary)
            Spacer() }
            .padding(.top, 4)
        }
    }

    private var signedInState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(Color.mint.opacity(0.14)).frame(width: 96, height: 96)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.mint)
            }
            .padding(.top, 20)

            VStack(spacing: 8) {
                Text("You're in!").font(.system(.title, design: .rounded).bold())
                Text("Signed in with \(socialAuth.authProvider.displayName)")
                    .foregroundStyle(.secondary)
                if socialAuth.authProvider == .github, let user = socialAuth.gitHubUser {
                    Label("@\(user.login)", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.subheadline.monospaced()).foregroundStyle(.mint)
                }
            }

            Button("Continue →") { onComplete() }
                .buttonStyle(.borderedProminent).tint(.mint)
                .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.15))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Provider Button

private struct ProviderButton: View {
    enum Style { case apple, google, github }
    let label: String
    let icon: String
    let style: Style
    let busy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if busy {
                    ProgressView().tint(style == .google ? Color(red: 0.2, green: 0.2, blue: 0.2) : .white)
                        .frame(width: 26)
                } else {
                    Image(systemName: icon).font(.title3.bold()).frame(width: 26)
                }
                Text(label).font(.headline)
                Spacer()
            }
            .foregroundStyle(style == .google ? Color(red: 0.18, green: 0.18, blue: 0.18) : .white)
            .padding(.vertical, 15).padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(bgColor, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style == .google ? Color(red: 0.78, green: 0.78, blue: 0.78) : Color.clear,
                            lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .accessibilityAddTraits(.isButton)
    }

    private var bgColor: Color {
        switch style {
        case .apple: return .black
        case .google: return .white
        case .github: return Color(red: 0.09, green: 0.09, blue: 0.09)
        }
    }
}

// MARK: - GitHub Studio Panel

struct GitHubStudioPanel: View {
    @EnvironmentObject var socialAuth: SocialAuthManager
    @State private var showConnect = false
    @State private var showRepoPicker = false
    @AppStorage("github.studio.expanded") private var expanded = true

    var body: some View {
        Group {
            if socialAuth.gitHubUser != nil || socialAuth.authProvider == .github {
                connectedPanel
            } else {
                inviteCard
            }
        }
        .sheet(isPresented: $showConnect) { GitHubConnectSheet() }
        .sheet(isPresented: $showRepoPicker) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        GitHubRepoPicker(onConnected: nil)
                    }
                    .padding(24)
                }
                .background(SprintPalette.navy.ignoresSafeArea())
                .navigationTitle("Choose a Repository")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showRepoPicker = false }
                }}
            }
        }
    }

    private var connectedPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.09, green: 0.09, blue: 0.09))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.subheadline.bold()).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if let user = socialAuth.gitHubUser {
                        Text("@\(user.login)").font(.headline)
                        Text("\(user.publicRepos) repos · \(user.followers) followers")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("GitHub connected").font(.headline)
                    }
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            if expanded {
                if socialAuth.connectedRepos.isEmpty {
                    connectRepoButton
                } else {
                    connectedReposList
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.09, green: 0.09, blue: 0.09).opacity(0.55),
                    in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.10)))
    }

    private var connectRepoButton: some View {
        Button { showRepoPicker = true } label: {
            HStack {
                Image(systemName: "plus.circle.fill").foregroundStyle(.mint)
                Text("Connect a repository").font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(14)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mint.opacity(0.4)))
        }
        .buttonStyle(.plain)
    }

    private var connectedReposList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(socialAuth.connectedRepos) { repo in
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill.badge.gearshape").foregroundStyle(.mint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(repo.name).font(.subheadline.bold())
                        if let lang = repo.language { LanguageChip(language: lang) }
                    }
                    Spacer()
                    Text("Connected").font(.caption).foregroundStyle(.mint)
                }
                .padding(12)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12))
            }
            Button { showRepoPicker = true } label: {
                Label("Connect another repository", systemImage: "plus.circle")
                    .font(.subheadline).foregroundStyle(.mint)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    private var inviteCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.09, green: 0.09, blue: 0.09))
                    .frame(width: 52, height: 52)
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.title2.bold()).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Connect GitHub").font(.headline)
                Text("Push practice commits to your repos")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Connect →") { showConnect = true }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.09, green: 0.09, blue: 0.09))
                .font(.subheadline.bold())
        }
        .padding(16)
        .background(Color(red: 0.09, green: 0.09, blue: 0.09).opacity(0.30),
                    in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
    }
}

// MARK: - GitHub Connect Sheet (step-by-step modal)

struct GitHubConnectSheet: View {
    @EnvironmentObject var socialAuth: SocialAuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var errorMsg = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i <= step ? Color.mint : Color.secondary.opacity(0.28))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 28).padding(.top, 4).padding(.bottom, 24)

                ScrollView {
                    Group {
                        switch step {
                        case 0: connectAccountStep
                        case 1: repoPickerStep
                        default: successStep
                        }
                    }
                    .padding(.horizontal, 28).padding(.bottom, 50)
                }
            }
            .background(SprintPalette.navy.ignoresSafeArea())
            .navigationTitle(["Connect GitHub", "Pick a Repository", "All Set!"][min(step, 2)])
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if step == 1 {
                        Button("Skip") { step = 2 }.foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // Step 0 — Connect account

    private var connectAccountStep: some View {
        VStack(spacing: 30) {
            // GitHub-style icon
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(red: 0.09, green: 0.09, blue: 0.09))
                    .frame(width: 108, height: 108)
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 54, weight: .semibold)).foregroundStyle(.white)
            }
            .padding(.top, 8)

            VStack(spacing: 10) {
                Text("Link your GitHub account")
                    .font(.system(.title2, design: .rounded).bold())
                Text("Connect once and your Studio practice sessions can push commits directly to your repositories — showing real activity on your GitHub profile.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                featureLine("folder.fill", "Choose which repos accept practice commits")
                featureLine("arrow.up.doc.fill", "Commits show up on your GitHub activity graph")
                featureLine("lock.shield.fill", "Only reads and writes to repos you select")
                featureLine("star.fill", "Build a real portfolio from day one")
            }
            .padding(18)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 18))

            if !errorMsg.isEmpty {
                Text(errorMsg).font(.caption).foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if socialAuth.gitHubUser != nil {
                Button("Continue to Repositories →") { step = 1 }
                    .buttonStyle(.borderedProminent).tint(.mint)
                    .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.15))
                    .frame(maxWidth: .infinity)
            } else {
                Button {
                    errorMsg = ""
                    Task {
                        do { try await socialAuth.signInWithGitHub(); step = 1 }
                        catch { errorMsg = error.localizedDescription }
                    }
                } label: {
                    HStack(spacing: 12) {
                        if socialAuth.busy {
                            ProgressView().tint(.white).frame(width: 20)
                        } else {
                            Image(systemName: "chevron.left.forwardslash.chevron.right").frame(width: 20)
                        }
                        Text("Continue with GitHub").font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(16)
                    .background(Color(red: 0.09, green: 0.09, blue: 0.09),
                                in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain).disabled(socialAuth.busy)
            }
        }
        .frame(maxWidth: .infinity).multilineTextAlignment(.center)
    }

    private func featureLine(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(.mint).frame(width: 20)
            Text(text).font(.subheadline)
            Spacer()
        }
    }

    // Step 1 — Pick a repo

    private var repoPickerStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let user = socialAuth.gitHubUser {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color(red: 0.09, green: 0.09, blue: 0.09)).frame(width: 44, height: 44)
                        Image(systemName: "person.fill").font(.headline).foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name ?? user.login).font(.headline)
                        Text("@\(user.login) · \(user.publicRepos) repositories")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Text("Choose a repository. Connected repos will receive a commit each time you save practice code in Studio.")
                .font(.subheadline).foregroundStyle(.secondary)

            GitHubRepoPicker(onConnected: { step = 2 })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Step 2 — Success

    private var successStep: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle().fill(Color.mint.opacity(0.14)).frame(width: 108, height: 108)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 54)).foregroundStyle(.mint)
            }
            .padding(.top, 20)

            VStack(spacing: 10) {
                Text("Repository connected!")
                    .font(.system(.title2, design: .rounded).bold())
                Text("Your practice sessions in Studio will now push commits to your connected repositories.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
            }

            if !socialAuth.connectedRepos.isEmpty {
                VStack(spacing: 8) {
                    ForEach(socialAuth.connectedRepos) { repo in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint)
                            Text(repo.fullName).font(.subheadline.monospaced())
                            Spacer()
                            if let lang = repo.language { LanguageChip(language: lang) }
                        }
                        .padding(12)
                        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            VStack(spacing: 12) {
                Text("What happens next").font(.headline)
                VStack(alignment: .leading, spacing: 10) {
                    stepNote("1", "Write or edit code in Studio")
                    stepNote("2", "Tap Save — a practice commit is queued")
                    stepNote("3", "Your GitHub activity graph updates")
                }
                .padding(16)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
            }

            Button("Back to Studio") { dismiss() }
                .buttonStyle(.borderedProminent).tint(.mint)
                .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.15))
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepNote(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold()).foregroundStyle(.mint)
                .frame(width: 22, height: 22)
                .background(Color.mint.opacity(0.14), in: Circle())
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - GitHub Repo Picker

struct GitHubRepoPicker: View {
    @EnvironmentObject var socialAuth: SocialAuthManager
    var onConnected: (() -> Void)?

    var body: some View {
        LazyVStack(spacing: 10) {
            if socialAuth.gitHubRepos.isEmpty {
                Text("No repositories found.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 30)
            } else {
                ForEach(socialAuth.gitHubRepos) { repo in
                    RepoRow(
                        repo: repo,
                        isConnected: socialAuth.isRepoConnected(repo)
                    ) {
                        socialAuth.connectRepo(repo)
                        onConnected?()
                    }
                }
            }
        }
    }
}

private struct RepoRow: View {
    let repo: GitHubRepo
    let isConnected: Bool
    let onConnect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isConnected ? .mint : .secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(repo.name).font(.headline)
                    if repo.isPrivate {
                        Text("private").font(.caption)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.secondary.opacity(0.14), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                if let desc = repo.description {
                    Text(desc).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                HStack(spacing: 8) {
                    if let lang = repo.language { LanguageChip(language: lang) }
                    if repo.stargazersCount > 0 {
                        Label("\(repo.stargazersCount)", systemImage: "star.fill")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            if !isConnected {
                Button("Connect", action: onConnect)
                    .buttonStyle(.borderedProminent).tint(.mint)
                    .foregroundStyle(Color(red: 0.06, green: 0.16, blue: 0.15))
                    .controlSize(.small)
            } else {
                Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.mint)
            }
        }
        .padding(14)
        .background(isConnected ? Color.mint.opacity(0.07) : SprintPalette.card,
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isConnected ? Color.mint.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Language Chip

struct LanguageChip: View {
    let language: String
    var body: some View {
        Text(language)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(chipColor.opacity(0.18), in: Capsule())
            .foregroundStyle(chipColor)
    }
    private var chipColor: Color {
        switch language.lowercased() {
        case "javascript": return Color(red: 0.97, green: 0.82, blue: 0.22)
        case "python":     return Color(red: 0.22, green: 0.52, blue: 0.82)
        case "html":       return Color(red: 0.94, green: 0.40, blue: 0.20)
        case "css":        return Color(red: 0.28, green: 0.58, blue: 0.97)
        case "swift":      return Color(red: 0.98, green: 0.48, blue: 0.22)
        case "typescript": return Color(red: 0.18, green: 0.45, blue: 0.82)
        default:           return .secondary
        }
    }
}
