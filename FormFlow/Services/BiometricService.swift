import Foundation
import LocalAuthentication

// MARK: - Biometric Authentication Service

@MainActor
class BiometricService: ObservableObject {
    static let shared = BiometricService()

    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?

    enum BiometricType {
        case none
        case faceID
        case touchID
        case opticID

        var displayName: String {
            switch self {
            case .none: return "Biometrics"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            }
        }

        var iconName: String {
            switch self {
            case .none: return "lock"
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            }
        }
    }

    init() {
        checkBiometricAvailability()
    }

    // MARK: - Check Availability

    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }

        switch context.biometryType {
        case .faceID:
            biometricType = .faceID
        case .touchID:
            biometricType = .touchID
        case .opticID:
            biometricType = .opticID
        case .none:
            biometricType = .none
        @unknown default:
            biometricType = .none
        }
    }

    var isAvailable: Bool {
        biometricType != .none
    }

    // MARK: - Authenticate

    func authenticate(reason: String = "Unlock FormFlow") async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometric authentication unavailable"
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            isAuthenticated = success
            errorMessage = nil
            return success
        } catch let authError as LAError {
            switch authError.code {
            case .userCancel:
                errorMessage = nil // User cancelled, not an error
            case .userFallback:
                return await authenticateWithPasscode()
            case .biometryNotAvailable:
                errorMessage = "\(biometricType.displayName) is not available"
            case .biometryNotEnrolled:
                errorMessage = "\(biometricType.displayName) is not set up"
            case .biometryLockout:
                errorMessage = "\(biometricType.displayName) is locked. Use your passcode."
                return await authenticateWithPasscode()
            default:
                errorMessage = "Authentication failed"
            }
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Passcode Fallback

    func authenticateWithPasscode() async -> Bool {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock FormFlow with your passcode"
            )
            isAuthenticated = success
            return success
        } catch {
            errorMessage = "Passcode authentication failed"
            return false
        }
    }
}
