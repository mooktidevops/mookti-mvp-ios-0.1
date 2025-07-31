//
//  AuthService.swift
//  Mookti
//
//  Created by GPT‑Assistant on 2025‑07‑04.
//

import Foundation
import AuthenticationServices
import Combine
import Security

@MainActor
final class AuthService: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Published state
    @Published private(set) var isSignedIn = false
    @Published private(set) var userID: String?
    @Published private(set) var isAdminMode = false

    private static let keychainAccount = "appleUserID"
    private static let keychainService = "com.mookti.auth"

    // MARK: - Init: restore any existing session
    private init() {
        if let savedID = Keychain.load(account: Self.keychainAccount,
                                       service: Self.keychainService) {
            userID = savedID
            isSignedIn = true
        }
    }

    // MARK: - Public API -----------------------------------------------------

    /// Call from `LoginView` after Sign‑in‑with‑Apple succeeds.
    func handleAuthorization(_ auth: ASAuthorization) async throws {
        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        let id = credential.user
        guard !id.isEmpty else { throw AuthError.invalidCredential }

        try Keychain.save(id,
                          account: Self.keychainAccount,
                          service: Self.keychainService)

        userID     = id
        isSignedIn = true
    }

    /// Used by MenuOverlayView “Log Out”.
    func logout() async {
        Keychain.delete(account: Self.keychainAccount,
                        service: Self.keychainService)
        userID     = nil
        isSignedIn = false
        isAdminMode = false
    }
    
    /// Admin login - no credentials required for internal beta
    func adminLogin() {
        userID = "admin_user"
        isSignedIn = true
        isAdminMode = true
    }

    // MARK: - Errors
    enum AuthError: LocalizedError {
        case invalidCredential
        var errorDescription: String? {
            switch self {
            case .invalidCredential: "Unable to parse Apple ID credential."
            }
        }
    }
}

// MARK: - Minimal Keychain helper -------------------------------------------

private enum Keychain {

    static func save(_ string: String, account: String, service: String) throws {
        let data = Data(string.utf8)

        // delete any existing value first
        delete(account: account, service: service)

        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : account,
            kSecAttrService : service,
            kSecValueData   : data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw keychainError(status) }
    }

    static func load(account: String, service: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : account,
            kSecAttrService : service,
            kSecReturnData  : kCFBooleanTrue!,
            kSecMatchLimit  : kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let str  = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    static func delete(account: String, service: String) {
        let query: [CFString: Any] = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : account,
            kSecAttrService : service
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func keychainError(_ status: OSStatus) -> NSError {
        NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
    }
}
