import Combine
import Foundation
import Security

struct BackendConfig: Decodable {
    let url: String
    let publishableKey: String
    let curriculumURL: String?

    // Returns the curriculum URL independently of whether the full backend is configured.
    static var remoteCurriculumURL: String? {
        guard let file = Bundle.main.url(forResource: "BackendConfig", withExtension: "json"),
              let data = try? Data(contentsOf: file),
              let config = try? JSONDecoder().decode(Self.self, from: data),
              let url = config.curriculumURL,
              !url.isEmpty
        else { return nil }
        return url
    }

    static var current: BackendConfig? {
        guard let file = Bundle.main.url(forResource: "BackendConfig", withExtension: "json"),
              let data = try? Data(contentsOf: file),
              let config = try? JSONDecoder().decode(Self.self, from: data),
              let url = URL(string: config.url), url.scheme == "https",
              !config.url.contains("YOUR_PROJECT"),
              !config.publishableKey.isEmpty,
              !config.publishableKey.contains("YOUR_") else { return nil }
        return config
    }
}

struct AuthUser: Codable { let id: String; let email: String? }

struct Session: Codable {
    let access_token: String
    let refresh_token: String
    let expires_at: Double?
    let user: AuthUser
}

enum Vault {
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "StackSprint.session",
         kSecAttrAccount as String: "current"]
    }

    static func read() -> Data? {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func save(_ data: Data) throws {
        SecItemDelete(query as CFDictionary)
        var q = query
        q[kSecValueData as String] = data
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(q as CFDictionary, nil) == errSecSuccess else {
            throw NSError(domain: "Keychain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not securely save this session."])
        }
    }

    static func clear() { SecItemDelete(query as CFDictionary) }
}

@MainActor final class Backend: ObservableObject {
    @Published private(set) var session: Session?
    @Published var message = ""
    @Published var busy = false
    let config = BackendConfig.current

    init() {
        if let data = Vault.read() { session = try? JSONDecoder().decode(Session.self, from: data) }
    }

    private func request(_ path: String, method: String = "POST", body: Data? = nil, authenticated: Bool = false) async throws -> Data {
        guard let config, let url = URL(string: config.url + path) else {
            throw failure("Backend is not configured. Follow SETUP.md; guest lessons work offline.")
        }
        if authenticated { try await refreshIfNeeded() }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        req.timeoutInterval = 25
        req.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated {
            guard let session else { throw failure("Sign in first.") }
            req.setValue("Bearer \(session.access_token)", forHTTPHeaderField: "Authorization")
        }
        if path.hasPrefix("/rest/v1/progress") {
            req.setValue("resolution=ignore-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw failure(object?["msg"] as? String ?? object?["message"] as? String ?? object?["error_description"] as? String ?? "Request failed. Check your connection and backend setup.")
        }
        return data
    }

    private func failure(_ text: String) -> NSError {
        NSError(domain: "StackSprint", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
    }

    private func json(_ value: [String: String]) throws -> Data {
        try JSONSerialization.data(withJSONObject: value)
    }

    private func install(_ data: Data) throws {
        let value = try JSONDecoder().decode(Session.self, from: data)
        try Vault.save(data)
        session = value
    }

    private func refreshIfNeeded() async throws {
        guard let s = session else { throw failure("Sign in first.") }
        if (s.expires_at ?? 0) > Date().timeIntervalSince1970 + 90 { return }
        let data = try await request("/auth/v1/token?grant_type=refresh_token", body: json(["refresh_token": s.refresh_token]))
        try install(data)
    }

    func signIn(email: String, password: String) async throws {
        try install(await request("/auth/v1/token?grant_type=password", body: json(["email": email.trimmingCharacters(in: .whitespacesAndNewlines), "password": password])))
    }

    func signUp(email: String, password: String) async throws {
        guard password.count >= 8 else { throw failure("Use at least eight characters for your password.") }
        let data = try await request("/auth/v1/signup", body: json(["email": email.trimmingCharacters(in: .whitespacesAndNewlines), "password": password]))
        if (try? JSONDecoder().decode(Session.self, from: data)) != nil { try install(data) }
        else { message = "Check your email to confirm your account, then sign in here." }
    }

    func sync(_ store: LearningStore) async throws {
        guard let id = session?.user.id else { throw failure("Sign in first.") }
        let rows = store.completed.map { ProgressRow(user_id: id, lesson_id: $0) }
        if !rows.isEmpty {
            _ = try await request("/rest/v1/progress?on_conflict=user_id,lesson_id", body: JSONEncoder().encode(rows), authenticated: true)
        }
        let data = try await request("/rest/v1/progress?select=user_id,lesson_id", method: "GET", authenticated: true)
        store.merge(try JSONDecoder().decode([ProgressRow].self, from: data))
        message = "Native lesson progress synced."
    }

    func signOut() async {
        if session != nil { _ = try? await request("/auth/v1/logout", authenticated: true) }
        Vault.clear(); session = nil; message = "Signed out on this device."
    }

    func deleteAccount() async throws {
        _ = try await request("/rest/v1/rpc/delete_my_account", body: Data("{}".utf8), authenticated: true)
        Vault.clear(); session = nil; message = "Account and server progress deleted."
    }
}
