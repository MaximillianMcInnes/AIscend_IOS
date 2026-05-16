//
//  ScanAnalysisService.swift
//  AIscend
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

protocol ScanAnalysisServiceProtocol: Sendable {
    func analyze(frontImageData: Data, sideImageData: Data, email: String?, userID: String?, isPremium: Bool) async throws -> PersistedScanRecord
}

actor ScanAnalysisService: ScanAnalysisServiceProtocol {
    private let apiClient: FaceScanAPIClient

    init(
        configuration: AIscendChatConfiguration = .live,
        session: URLSession? = nil
    ) {
        self.apiClient = FaceScanAPIClient(configuration: configuration, session: session)
    }

    func analyze(frontImageData: Data, sideImageData: Data, email: String?, userID: String?, isPremium: Bool) async throws -> PersistedScanRecord {
        let authContext = try await firebaseAuthContext(fallbackEmail: email)
        let uploadedImages = try await uploadScanImages(
            frontImageData: frontImageData,
            sideImageData: sideImageData,
            userID: userID ?? authContext.userID
        )

        // Backend must verify the Firebase ID token and confirm Users/{uid}.isPremium or subscription == Paid server-side.
        return try await apiClient.analyze(
            frontImageURL: uploadedImages.frontURL,
            sideImageURL: uploadedImages.sideURL,
            email: authContext.email,
            idToken: authContext.idToken,
            subscription: isPremium ? "paid" : "free"
        )
    }
}

private extension ScanAnalysisService {
    struct FirebaseAuthContext {
        let idToken: String
        let email: String
        let userID: String?
    }

    struct UploadedScanImages {
        let frontURL: String
        let sideURL: String
    }

    func uploadScanImages(frontImageData: Data, sideImageData: Data, userID: String?) async throws -> UploadedScanImages {
        #if canImport(FirebaseStorage)
        guard let safeUserID = userID?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else {
            throw ScanAnalysisError.notAuthenticated
        }

        let root = Storage.storage().reference().child("users/\(safeUserID)/uploads")
        async let frontURL = uploadImage(frontImageData, to: root.child("front_\(UUID().uuidString).jpg"), userID: safeUserID, kind: "front")
        async let sideURL = uploadImage(sideImageData, to: root.child("side_\(UUID().uuidString).jpg"), userID: safeUserID, kind: "side")

        return try await UploadedScanImages(frontURL: frontURL, sideURL: sideURL)
        #else
        throw ScanAnalysisError.upload("Scan photo upload is not configured in this build. Add Firebase Storage before running backend face scans.")
        #endif
    }

    #if canImport(FirebaseStorage)
    func uploadImage(_ data: Data, to reference: StorageReference, userID: String, kind: String) async throws -> String {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.cacheControl = "public, max-age=31536000, immutable"
        metadata.customMetadata = [
            "uid": userID,
            "kind": kind,
            "originalName": "\(kind).jpg"
        ]

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                reference.putData(data, metadata: metadata) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }

            let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                reference.downloadURL { url, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: ScanAnalysisError.upload("AIScend could not create a download URL for your scan photos. Please try again."))
                    }
                }
            }

            return url.absoluteString
        } catch {
            throw ScanAnalysisError.upload("AIScend could not upload your scan photos. Check your connection and try again.")
        }
    }
    #endif

    func firebaseAuthContext(fallbackEmail: String?) async throws -> FirebaseAuthContext {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw ScanAnalysisError.notAuthenticated
        }

        let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? fallbackEmail?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        guard let email else {
            throw ScanAnalysisError.missingEmail
        }

        let idToken = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            user.getIDTokenForcingRefresh(true) { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token, !token.isEmpty {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: ScanAnalysisError.notAuthenticated)
                }
            }
        }

        return FirebaseAuthContext(idToken: idToken, email: email, userID: user.uid)
        #else
        throw ScanAnalysisError.notAuthenticated
        #endif
    }
}

enum ScanAnalysisError: LocalizedError, Equatable {
    case missingBaseURL
    case invalidEndpointURL(String)
    case notAuthenticated
    case missingEmail
    case missingImageURL(String)
    case uploadURLNotResolved(String)
    case emptyResponse
    case decodingFailed(String)
    case invalidResponse
    case upload(String)
    case transport(String)
    case backend(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            "Add `API_BASE_URL` to the app configuration before running a scan."
        case .invalidEndpointURL(let url):
            "The scan endpoint is invalid: \(url)"
        case .notAuthenticated:
            "Sign in before running a private scan."
        case .missingEmail:
            "Your signed-in account is missing an email address, so AIScend cannot start the scan."
        case .missingImageURL(let label):
            "AIScend could not find the \(label) image URL before starting the scan."
        case .uploadURLNotResolved(let label):
            "AIScend could not resolve the \(label) upload into a downloadable HTTPS URL."
        case .emptyResponse:
            "AIScend returned an empty scan response."
        case .decodingFailed(let raw):
            #if DEBUG
            raw.isEmpty
            ? "AIScend returned a scan response that could not be decoded."
            : "AIScend returned a scan response that could not be decoded.\n\nRaw response: \(raw)"
            #else
            "AIScend returned a scan response that could not be decoded."
            #endif
        case .invalidResponse:
            "AIScend returned an unreadable scan result. Please try again."
        case .upload(let message), .transport(let message):
            message
        case .backend(_, let message):
            message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .missingBaseURL, .invalidEndpointURL:
            return "Open the app configuration and set `API_BASE_URL` to your FastAPI host. The scan path should resolve to `/api/face_scan`."
        case .notAuthenticated, .missingEmail:
            return "Sign in again, then rerun the scan."
        case .missingImageURL, .uploadURLNotResolved:
            return "Try uploading the front and side photos again so AIScend can generate fresh download URLs."
        case .emptyResponse, .decodingFailed, .invalidResponse:
            return "Try again. If this keeps happening, the backend response format may need checking."
        case .upload:
            return "Use a stable connection and make sure photo upload permissions are available."
        case .transport:
            return "Check your connection, then try running the scan again."
        case .backend(let statusCode, _):
            switch statusCode {
            case 400:
                return "Use a clear front selfie and a clean side-profile photo. Make sure only one face is visible."
            case 401:
                return "Sign in again so AIScend can refresh your secure token."
            case 403:
                return "Make sure the account email matches the signed-in user and that your access is active."
            default:
                return "Try again in a moment. If it keeps failing, send this message to support."
            }
        }
    }

    var alertTitle: String {
        switch self {
        case .missingBaseURL, .invalidEndpointURL:
            return "Scan server missing"
        case .notAuthenticated, .missingEmail:
            return "Sign in required"
        case .missingImageURL, .uploadURLNotResolved:
            return "Photo URL missing"
        case .emptyResponse, .decodingFailed, .invalidResponse:
            return "Result unreadable"
        case .upload:
            return "Photo upload failed"
        case .transport:
            return "Connection problem"
        case .backend(let statusCode, _):
            switch statusCode {
            case 400:
                return "Fix your photos"
            case 401:
                return "Session expired"
            case 403:
                return "Account mismatch"
            default:
                return "Scan failed"
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
