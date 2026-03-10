import Foundation
import CryptoKit

// MARK: - Signature Service

class SignatureService {
    static let shared = SignatureService()

    func computeSignatureHash(
        workflowId: String,
        stepNumber: Int,
        signerId: String,
        signerName: String,
        signerRole: String,
        timestamp: String,
        deviceId: String,
        attestationText: String,
        signatureImageData: Data
    ) -> String {
        let base64Sig = signatureImageData.base64EncodedString()
        let combined = "\(workflowId)|\(stepNumber)|\(signerId)|\(signerName)|\(signerRole)|\(timestamp)|\(deviceId)|\(attestationText)|\(base64Sig)"
        let inputData = Data(combined.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func createSignatureRecord(
        workflowId: UUID,
        stepNumber: Int,
        signer: FFUser,
        signatureImageData: Data,
        attestationText: String
    ) -> SignatureRecord {
        let timestamp = Date()
        let isoFormatter = ISO8601DateFormatter()
        let timestampString = isoFormatter.string(from: timestamp)

        let hash = computeSignatureHash(
            workflowId: workflowId.uuidString,
            stepNumber: stepNumber,
            signerId: signer.id.uuidString,
            signerName: signer.displayName,
            signerRole: signer.role.rawValue,
            timestamp: timestampString,
            deviceId: signer.deviceId,
            attestationText: attestationText,
            signatureImageData: signatureImageData
        )

        return SignatureRecord(
            id: UUID(),
            workflowId: workflowId,
            stepNumber: stepNumber,
            signerId: signer.id,
            signerName: signer.displayName,
            signerRole: signer.role.rawValue,
            signatureImageData: signatureImageData,
            attestationText: attestationText,
            deviceId: signer.deviceId,
            timestamp: timestamp,
            ipAddress: nil,
            mfaVerified: signer.mfaEnabled,
            contentHash: hash,
            synced: false
        )
    }
}
