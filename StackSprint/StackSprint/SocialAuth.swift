import AuthenticationServices
import Combine
import Foundation
import Security
import SwiftUI

// MARK: - Models

struct AppleSignInResult {
    let userID: String
    let email: String?
    let fullName: String?
}

struct GitHubUser: Codable {
    let login: String
    let name: String?
    let bio: String?
    let publicRepos: Int
    let followers: Int
    enum CodingKeys: String, CodingKey {
        case login, name, bio, followers
        case publicRepos = "public_repos"
    }
}

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let isPrivate: Bool
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case fullName = "full_name"
        case stargazersCount = "stargazers_count"
        case isPrivate = "private"
    }
}

enum AuthProvider: String, Codable {
    case none, apple, github, google, email
    var displayName: String {
        switch self {
        case .none: return "Guest"
        case .apple: return "Apple"
        case .github: return "GitHub"
        case .google: return "Google"
        case .email: return "Email"
        }
    }
    var systemImage: String {
        switch self {
        case .none: return "person.crop.circle"
        case .apple: return "apple.logo"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }
}

// MARK: - SocialAuthManager

@MainActor final class SocialAuthManager: NSObject, ObservableObject {
    @Published private(set) var authProvider: AuthProvider = .none
    @Published private(set) var appleDisplayName: String?
    @Published private(set) var gitHubUser: GitHubUser?
    @Published private(set) var gitHubRepos: [GitHubRepo] = []
    @Published private(set) var connectedRepoIDs: Set<Int> = []
    @Published var busy = false
    @Published var message = ""

    // Set your OAuth App credentials here before enabling live auth.
    // Without credentials, demo mode simulates a real connection.
    static let gitHubClientID = ""
    static let googleClientID = ""
    static let redirectScheme = "stacksprint"

    var isSignedIn: Bool { authProvider != .none }
    var connectedRepos: [GitHubRepo] { gitHubRepos.filter { connectedRepoIDs.contains($0.id) } }

    var displayName: String {
        switch authProvider {
        case .none: return "Guest"
        case .apple:
            return appleDisplayName
                ?? UserDefaults.standard.string(forKey: "social.apple.email")
                ?? "Apple User"
        case .github: return gitHubUser.map { "@\($0.login)" } ?? "GitHub User"
        case .google: return UserDefaults.standard.string(forKey: "social.google.name") ?? "Google User"
        case .email: return UserDefaults.standard.string(forKey: "social.email.address") ?? "User"
        }
    }

    override init() {
        super.init()
        restore()
    }

    private func restore() {
        if let raw = UserDefaults.standard.string(forKey: "social.provider"),
           let p = AuthProvider(rawValue: raw) { authProvider = p }
        appleDisplayName = UserDefaults.standard.string(forKey: "social.apple.name")
        if let data = UserDefaults.standard.data(forKey: "social.github.user"),
           let u = try? JSONDecoder().decode(GitHubUser.self, from: data) { gitHubUser = u }
        if let data = UserDefaults.standard.data(forKey: "social.github.repos"),
           let r = try? JSONDecoder().decode([GitHubRepo].self, from: data) { gitHubRepos = r }
        connectedRepoIDs = Set(
            UserDefaults.standard.array(forKey: "github.connectedRepos") as? [Int] ?? []
        )
    }

    // MARK: Apple

    func signInWithApple() async throws {
        busy = true; defer { busy = false }
        let delegate = AppleDelegate()
        let result = try await delegate.perform()
        authProvider = .apple
        appleDisplayName = result.fullName
        UserDefaults.standard.set("apple", forKey: "social.provider")
        if let n = result.fullName { UserDefaults.standard.set(n, forKey: "social.apple.name") }
        if let e = result.email { UserDefaults.standard.set(e, forKey: "social.apple.email") }
        UserDefaults.standard.set(result.userID, forKey: "social.apple.userID")
    }

    // MARK: GitHub

    func signInWithGitHub() async throws {
        busy = true; defer { busy = false }
        if Self.gitHubClientID.isEmpty {
            // Demo: simulate OAuth + API response
            try await Task.sleep(nanoseconds: 1_400_000_000)
            gitHubUser = GitHubUser(
                login: "you",
                name: "Your GitHub",
                bio: "Learning to build with StackSprint",
                publicRepos: 8,
                followers: 3
            )
            gitHubRepos = Self.demoRepos
            authProvider = .github
            UserDefaults.standard.set("github", forKey: "social.provider")
            persistGitHub()
            return
        }
        let redirect = (Self.redirectScheme + "://github/callback")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let authURL = URL(string: "https://github.com/login/oauth/authorize?client_id=\(Self.gitHubClientID)&scope=read:user,public_repo&redirect_uri=\(redirect)") else {
            throw makeError("Invalid GitHub OAuth URL. Set a valid gitHubClientID.")
        }
        let callback = try await openWebAuth(url: authURL, scheme: Self.redirectScheme)
        guard URLComponents(url: callback, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "code" }) != nil else {
            throw makeError("GitHub did not return an authorization code.")
        }
        // Exchange the code for an access token via your backend, then call loadGitHubUser(token:).
        message = "GitHub code received. Configure a backend endpoint to exchange it for a token."
    }

    // MARK: Google

    func signInWithGoogle() async throws {
        busy = true; defer { busy = false }
        if Self.googleClientID.isEmpty {
            // Demo: simulate OAuth
            try await Task.sleep(nanoseconds: 900_000_000)
            authProvider = .google
            UserDefaults.standard.set("google", forKey: "social.provider")
            UserDefaults.standard.set("Coder", forKey: "social.google.name")
            return
        }
        let redirect = (Self.redirectScheme + "://google/callback")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let authURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(Self.googleClientID)&redirect_uri=\(redirect)&response_type=code&scope=openid%20email%20profile") else {
            throw makeError("Invalid Google OAuth URL. Set a valid googleClientID.")
        }
        _ = try await openWebAuth(url: authURL, scheme: Self.redirectScheme)
        authProvider = .google
        UserDefaults.standard.set("google", forKey: "social.provider")
    }

    // MARK: Repo Management

    func connectRepo(_ repo: GitHubRepo) {
        connectedRepoIDs.insert(repo.id)
        UserDefaults.standard.set(Array(connectedRepoIDs), forKey: "github.connectedRepos")
    }

    func disconnectRepo(_ repo: GitHubRepo) {
        connectedRepoIDs.remove(repo.id)
        UserDefaults.standard.set(Array(connectedRepoIDs), forKey: "github.connectedRepos")
    }

    func isRepoConnected(_ repo: GitHubRepo) -> Bool { connectedRepoIDs.contains(repo.id) }

    // MARK: Sign Out

    func signOut() {
        authProvider = .none
        appleDisplayName = nil
        gitHubUser = nil
        gitHubRepos = []
        connectedRepoIDs = []
        ["social.provider", "social.apple.name", "social.apple.email", "social.apple.userID",
         "social.github.user", "social.github.repos", "github.connectedRepos", "social.google.name"
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        message = "Disconnected."
    }

    // MARK: Helpers

    private func openWebAuth(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            var session: ASWebAuthenticationSession?
            session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme
            ) { callbackURL, error in
                if let error { continuation.resume(throwing: error) }
                else if let url = callbackURL { continuation.resume(returning: url) }
                else { continuation.resume(throwing: self.makeError("Auth returned no URL.")) }
                session = nil
            }
            session?.presentationContextProvider = WebAuthContext.shared
            session?.prefersEphemeralWebBrowserSession = false
            session?.start()
        }
    }

    func makeError(_ msg: String) -> NSError {
        NSError(domain: "SocialAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }

    private func persistGitHub() {
        if let d = try? JSONEncoder().encode(gitHubUser) {
            UserDefaults.standard.set(d, forKey: "social.github.user")
        }
        if let d = try? JSONEncoder().encode(gitHubRepos) {
            UserDefaults.standard.set(d, forKey: "social.github.repos")
        }
    }

    private static var demoRepos: [GitHubRepo] { [
        GitHubRepo(id: 101, name: "my-portfolio",
                   fullName: "you/my-portfolio",
                   description: "Personal portfolio site built with HTML & CSS",
                   language: "HTML", stargazersCount: 0, isPrivate: false),
        GitHubRepo(id: 102, name: "python-practice",
                   fullName: "you/python-practice",
                   description: "Python exercises from StackSprint daily sprints",
                   language: "Python", stargazersCount: 2, isPrivate: false),
        GitHubRepo(id: 103, name: "css-experiments",
                   fullName: "you/css-experiments",
                   description: "CSS animations, layouts, and mini-games",
                   language: "CSS", stargazersCount: 1, isPrivate: false),
        GitHubRepo(id: 104, name: "first-js-app",
                   fullName: "you/first-js-app",
                   description: "My first JavaScript web app",
                   language: "JavaScript", stargazersCount: 0, isPrivate: false),
    ] }
}

// MARK: - Live GitHub API (same-file extension — private access OK)

extension SocialAuthManager {

    private static let gitHubTokenService = "StackSprint.github.token"

    var gitHubToken: String? {
        get { keychainString(service: Self.gitHubTokenService) }
        set {
            if let v = newValue { keychainWrite(service: Self.gitHubTokenService, value: v) }
            else { keychainDelete(service: Self.gitHubTokenService) }
        }
    }

    // Call after your backend exchanges the OAuth code for an access token.
    func installGitHubToken(_ token: String) async throws {
        gitHubToken = token
        try await refreshGitHubProfile()
    }

    func refreshGitHubProfile() async throws {
        guard let token = gitHubToken else { return }
        async let userFetch: GitHubUser = apiGet("/user", token: token)
        async let reposFetch: [GitHubRepo] = apiGet("/user/repos?per_page=50&sort=pushed", token: token)
        let (user, repos) = try await (userFetch, reposFetch)
        gitHubUser = user
        gitHubRepos = repos
        authProvider = .github
        UserDefaults.standard.set("github", forKey: "social.provider")
        persistGitHub()
    }

    // Creates or updates a practice file in the chosen repo via the GitHub Contents API.
    // Returns a human-readable confirmation string on success.
    func pushPracticeCommit(to repoFullName: String, language: String, code: String) async throws -> String {
        guard let token = gitHubToken else {
            // Demo mode: no real commit, just confirm locally
            return "Demo: \(language) practice logged for \(repoFullName) 🐙"
        }
        let ext = langExt(language)
        let date = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        let path = "stacksprint-practice/\(date)-\(language.lowercased()).\(ext)"
        let message = "[StackSprint] Practice · \(language) · \(date)"

        // Fetch existing SHA so we can update instead of create a conflict
        var sha: String?
        let getPath = "https://api.github.com/repos/\(repoFullName)/contents/\(path)"
        if let (data, resp) = try? await rawGet(getPath, token: token),
           (resp as? HTTPURLResponse)?.statusCode == 200,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            sha = json["sha"] as? String
        }

        var body: [String: Any] = [
            "message": message,
            "content": Data(code.utf8).base64EncodedString()
        ]
        if let sha { body["sha"] = sha }

        guard let url = URL(string: "https://api.github.com/repos/\(repoFullName)/contents/\(path)") else {
            throw makeError("Invalid repo path.")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...201).contains(http.statusCode) else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw makeError(msg ?? "Commit failed (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)).")
        }
        return "\(language) practice committed to \(repoFullName) 🐙"
    }

    // MARK: Private API helpers

    private func apiGet<T: Decodable>(_ path: String, token: String) async throws -> T {
        let urlStr = path.hasPrefix("http") ? path : "https://api.github.com\(path)"
        guard let url = URL(string: urlStr) else { throw makeError("Bad API URL.") }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw makeError(msg ?? "GitHub API error.")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func rawGet(_ urlStr: String, token: String) async throws -> (Data, URLResponse) {
        guard let url = URL(string: urlStr) else { throw makeError("Bad URL.") }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        return try await URLSession.shared.data(for: req)
    }

    private func langExt(_ lang: String) -> String {
        ["javascript": "js", "python": "py", "html": "html",
         "css": "css", "typescript": "ts", "swift": "swift"][lang.lowercased()] ?? "txt"
    }

    private func keychainString(service: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                 kSecAttrService as String: service,
                                 kSecReturnData as String: true,
                                 kSecMatchLimit as String: kSecMatchLimitOne]
        var r: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &r) == errSecSuccess,
              let d = r as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }

    private func keychainWrite(service: String, value: String) {
        keychainDelete(service: service)
        var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrService as String: service]
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }

    private func keychainDelete(service: String) {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                       kSecAttrService as String: service] as CFDictionary)
    }
}

// MARK: - Apple Delegate

private final class AppleDelegate: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var controller: ASAuthorizationController?

    func perform() async throws -> AppleSignInResult {
        try await withCheckedThrowingContinuation { c in
            self.continuation = c
            let req = ASAuthorizationAppleIDProvider().createRequest()
            req.requestedScopes = [.fullName, .email]
            let ctrl = ASAuthorizationController(authorizationRequests: [req])
            ctrl.delegate = self
            ctrl.presentationContextProvider = self
            self.controller = ctrl
            ctrl.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        self.controller = nil
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(domain: "Auth", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected credential type."]))
            return
        }
        let parts = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap { $0 }
        continuation?.resume(returning: AppleSignInResult(
            userID: cred.user,
            email: cred.email,
            fullName: parts.isEmpty ? nil : parts.joined(separator: " ")
        ))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        self.controller = nil
        continuation?.resume(throwing: error)
    }
}

// MARK: - Web Auth Presentation Context

final class WebAuthContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthContext()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}
