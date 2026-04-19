//
//  AuthSessionStore.swift
//  AIscend
//
//  Created by Codex on 4/7/26.
//

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Security
import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct SessionUser: Equatable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let email: String?
    let providerLabels: [String]
    let photoURL: URL?

    var subtitle: String {
        if let email, !email.isEmpty {
            return email
        }

        return providerLabels.joined(separator: " + ")
    }

    var initials: String {
        let words = displayName
            .split(whereSeparator: \.isWhitespace)
            .prefix(2)
            .compactMap { $0.first }

        let letters = String(words)
        return letters.isEmpty ? "AI" : letters.uppercased()
    }
}

@MainActor
@Observable
final class AuthSessionStore {
    enum Phase {
        case checking
        case signedOut
        case signedIn
    }

    private enum SessionError: LocalizedError {
        case firebaseUnavailable(String)
        case missingPresenter
        case missingGoogleClientID
        case missingGoogleIDToken
        case missingAppleNonce
        case missingAppleIdentityToken
        case invalidAppleCredential

        var errorDescription: String? {
            switch self {
            case .firebaseUnavailable(let message):
                message
            case .missingPresenter:
                "AIscend could not find a screen to present the sign-in flow."
            case .missingGoogleClientID:
                "Firebase is configured, but the Google client ID is missing."
            case .missingGoogleIDToken:
                "Google Sign-In finished without an ID token for Firebase."
            case .missingAppleNonce:
                "Apple Sign-In could not validate the request nonce."
            case .missingAppleIdentityToken:
                "Apple Sign-In finished without an identity token for Firebase."
            case .invalidAppleCredential:
                "Apple Sign-In returned an unexpected credential type."
            }
        }
    }

    var phase: Phase = .checking
    var user: SessionUser?
    var errorMessage: String?
    var configurationMessage: String?
    var isPerformingAuthAction: Bool = false

    private var currentNonce: String?

    #if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    #endif

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("--uitest-force-signed-in") {
            phase = .signedIn
            user = SessionUser(
                id: "ui-test-user",
                displayName: "UI Test User",
                email: "uitest@aiscend.local",
                providerLabels: ["UI Test"],
                photoURL: nil
            )
            return
        }

        if arguments.contains("--uitest-force-signed-out") {
            phase = .signedOut
            user = nil
            return
        }

        refreshAvailability()
        beginListeningIfNeeded()
    }

    var canUseAppleSignIn: Bool {
        configurationMessage == nil
    }

    var canUseGoogleSignIn: Bool {
        configurationMessage == nil && googleSDKStatusMessage == nil
    }

    var providerSummary: String {
        user?.providerLabels.joined(separator: " + ") ?? "No provider connected yet"
    }

    var googleSDKStatusMessage: String? {
        #if canImport(GoogleSignIn)
        nil
        #else
        "GoogleSignIn is not linked yet, so Google auth is disabled."
        #endif
    }

    func refreshAvailability() {
        configurationMessage = firebaseConfigurationStatusMessage()
        if configurationMessage != nil {
            phase = .signedOut
            user = nil
        }
    }

    func signInWithGoogle() async {
        refreshAvailability()

        if let configurationMessage {
            errorMessage = configurationMessage
            return
        }

        if let googleSDKStatusMessage {
            errorMessage = googleSDKStatusMessage
            return
        }

        #if canImport(FirebaseAuth) && canImport(FirebaseCore) && canImport(GoogleSignIn)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = SessionError.missingGoogleClientID.localizedDescription
            return
        }

        guard let presenter = UIApplication.shared.aiscendTopViewController else {
            errorMessage = SessionError.missingPresenter.localizedDescription
            return
        }

        isPerformingAuthAction = true
        errorMessage = nil

        defer {
            isPerformingAuthAction = false
        }

        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            let result: GIDSignInResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                GIDSignIn.sharedInstance.signIn(withPresenting: presenter) { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let result {
                        continuation.resume(returning: result)
                    } else {
                        continuation.resume(throwing: SessionError.missingGoogleIDToken)
                    }
                }
            }

            guard let idToken = result.user.idToken?.tokenString else {
                throw SessionError.missingGoogleIDToken
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            try await signInToFirebase(with: credential)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
        #else
        errorMessage = "Google Sign-In is unavailable in this build."
        #endif
    }

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        errorMessage = nil
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        Task {
            await completeAppleSignIn(result)
        }
    }

    func signOut() {
        refreshAvailability()

        if let configurationMessage {
            errorMessage = configurationMessage
            return
        }

        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
            #if canImport(GoogleSignIn)
            GIDSignIn.sharedInstance.signOut()
            #endif
            currentNonce = nil
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
        #else
        errorMessage = "FirebaseAuth is unavailable in this build."
        #endif
    }

    func updateDisplayName(_ displayName: String) async {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Name cannot be empty."
            return
        }

        refreshAvailability()

        #if canImport(FirebaseAuth)
        guard configurationMessage == nil else {
            return
        }

        guard let firebaseUser = Auth.auth().currentUser else {
            if let currentUser = user {
                user = SessionUser(
                    id: currentUser.id,
                    displayName: trimmedName,
                    email: currentUser.email,
                    providerLabels: currentUser.providerLabels,
                    photoURL: currentUser.photoURL
                )
            }
            return
        }

        isPerformingAuthAction = true
        defer { isPerformingAuthAction = false }

        do {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = trimmedName
            try await commitProfileChanges(changeRequest)
            try await reload(firebaseUser: firebaseUser)
            user = SessionUser(firebaseUser: firebaseUser)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
        #else
        if let currentUser = user {
            user = SessionUser(
                id: currentUser.id,
                displayName: trimmedName,
                email: currentUser.email,
                providerLabels: currentUser.providerLabels,
                photoURL: currentUser.photoURL
            )
        }
        #endif
    }

    private func beginListeningIfNeeded() {
        refreshAvailability()

        guard configurationMessage == nil else {
            return
        }

        #if canImport(FirebaseAuth)
        guard authStateHandle == nil else {
            return
        }

        phase = .checking
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else {
                return
            }

            Task { @MainActor in
                self.user = firebaseUser.map(SessionUser.init(firebaseUser:))
                self.phase = firebaseUser == nil ? .signedOut : .signedIn
            }
        }
        #else
        phase = .signedOut
        #endif
    }

    private func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        refreshAvailability()

        if let configurationMessage {
            errorMessage = configurationMessage
            return
        }

        #if canImport(FirebaseAuth)
        isPerformingAuthAction = true

        defer {
            isPerformingAuthAction = false
            currentNonce = nil
        }

        do {
            let authorization = try result.get()

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw SessionError.invalidAppleCredential
            }

            guard let currentNonce else {
                throw SessionError.missingAppleNonce
            }

            guard
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                throw SessionError.missingAppleIdentityToken
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: currentNonce,
                fullName: credential.fullName
            )

            try await signInToFirebase(with: firebaseCredential)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
        #else
        errorMessage = "Apple Sign-In is unavailable in this build."
        #endif
    }

    private func firebaseConfigurationStatusMessage() -> String? {
        if FirebaseBootstrapper.isReady {
            #if canImport(FirebaseAuth)
            return nil
            #endif
        }

        if let statusMessage = FirebaseBootstrapper.statusMessage {
            return statusMessage
        }

        #if canImport(FirebaseAuth)
        return "Firebase has not been configured yet."
        #else
        return "FirebaseAuth is not linked yet, so authentication is unavailable."
        #endif
    }

    #if canImport(FirebaseAuth)
    private func signInToFirebase(with credential: AuthCredential) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func commitProfileChanges(_ request: UserProfileChangeRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            request.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func reload(firebaseUser: User) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            firebaseUser.reload { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    #endif

    private func userFacingMessage(for error: Error) -> String? {
        if let sessionError = error as? SessionError {
            return sessionError.errorDescription
        }

        let nsError = error as NSError

        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue
        {
            return nil
        }

        #if canImport(GoogleSignIn)
        if nsError.domain == kGIDSignInErrorDomain,
           nsError.code == -5
        {
            return nil
        }
        #endif

        return nsError.localizedDescription
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}

#if canImport(FirebaseAuth)
private extension SessionUser {
    init(firebaseUser: User) {
        let providerLabels = firebaseUser.providerData
            .map(\.providerID)
            .compactMap(Self.providerLabel(for:))

        let fallbackName = firebaseUser.email ?? "Climber"
        let trimmedDisplayName = firebaseUser.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        self.init(
            id: firebaseUser.uid,
            displayName: trimmedDisplayName.isEmpty ? fallbackName : trimmedDisplayName,
            email: firebaseUser.email,
            providerLabels: providerLabels.isEmpty ? ["Firebase"] : providerLabels,
            photoURL: firebaseUser.photoURL
        )
    }

    private static func providerLabel(for providerID: String) -> String? {
        switch providerID {
        case "google.com":
            "Google"
        case "apple.com":
            "Apple"
        case "password":
            "Email"
        default:
            nil
        }
    }
}
#endif

private extension UIApplication {
    var aiscendTopViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .aiscendTopViewController
    }
}

private extension UIViewController {
    var aiscendTopViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.aiscendTopViewController
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.aiscendTopViewController ?? navigationController
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.aiscendTopViewController ?? tabBarController
        }

        return self
    }
}
