import Foundation
import Combine

@MainActor
final class AuthSession: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published private(set) var username = ""
    @Published var errorMessage = ""
    @Published var isLoading = false

    private enum Keys {
        static let token = "sunwell_auth_token"
        static let username = "sunwell_auth_username"
        static let expireAt = "sunwell_auth_expire_at"
    }

    private let defaults = UserDefaults.standard

    init() {
        loadLogin()
    }

    func loadSavedUsername() -> String {
        defaults.string(forKey: Keys.username) ?? ""
    }

    func loadLogin() {
        let savedUsername = defaults.string(forKey: Keys.username) ?? ""
        let savedToken = defaults.string(forKey: Keys.token) ?? ""
        let expireAt = defaults.object(forKey: Keys.expireAt) as? Date

        username = savedUsername

        guard !savedUsername.isEmpty,
              !savedToken.isEmpty,
              let expireAt = expireAt,
              Date() <= expireAt else {
            logout(keepUsername: true)
            return
        }

        APIClient.shared.credentials = AuthCredentials(token: savedToken, username: savedUsername)
        isLoggedIn = true
    }

    func login(username inputUsername: String, password: String) async {
        let trimmedUsername = inputUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            errorMessage = "Please input username and password."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            let response = try await APIClient.shared.login(username: trimmedUsername, password: password)

            guard response.success, let token = response.token, !token.isEmpty else {
                errorMessage = response.message?.nilIfBlank ?? "Login failed."
                isLoading = false
                return
            }

            let savedUsername = response.username?.nilIfBlank ?? trimmedUsername
            saveLogin(username: savedUsername, token: token)
            isLoading = false
        } catch {
            errorMessage = "Login error: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func logout(keepUsername: Bool = true) {
        let savedUsername = keepUsername ? (defaults.string(forKey: Keys.username) ?? username) : ""
        defaults.removeObject(forKey: Keys.token)
        defaults.removeObject(forKey: Keys.expireAt)

        if keepUsername {
            defaults.set(savedUsername, forKey: Keys.username)
        } else {
            defaults.removeObject(forKey: Keys.username)
        }

        APIClient.shared.credentials = nil
        username = savedUsername
        isLoggedIn = false
    }

    private func saveLogin(username: String, token: String) {
        let expireAt = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

        defaults.set(username, forKey: Keys.username)
        defaults.set(token, forKey: Keys.token)
        defaults.set(expireAt, forKey: Keys.expireAt)

        APIClient.shared.credentials = AuthCredentials(token: token, username: username)
        self.username = username
        isLoggedIn = true
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}



