import XCTest
import CryptoKit
@testable import FormFlow

final class SignatureServiceTests: XCTestCase {
    let service = SignatureService.shared

    // MARK: - Hash Generation

    func testSignatureHashIsConsistent() {
        let imageData = Data("test-signature-image".utf8)

        let hash1 = service.computeSignatureHash(
            workflowId: "wf-001",
            stepNumber: 1,
            signerId: "user-001",
            signerName: "John Doe",
            signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-12345678",
            attestationText: "I confirm this is accurate.",
            signatureImageData: imageData
        )

        let hash2 = service.computeSignatureHash(
            workflowId: "wf-001",
            stepNumber: 1,
            signerId: "user-001",
            signerName: "John Doe",
            signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-12345678",
            attestationText: "I confirm this is accurate.",
            signatureImageData: imageData
        )

        XCTAssertEqual(hash1, hash2, "Same inputs should produce the same hash")
    }

    func testSignatureHashChangesWithDifferentInputs() {
        let imageData = Data("test-signature-image".utf8)

        let hash1 = service.computeSignatureHash(
            workflowId: "wf-001",
            stepNumber: 1,
            signerId: "user-001",
            signerName: "John Doe",
            signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-12345678",
            attestationText: "I confirm this is accurate.",
            signatureImageData: imageData
        )

        let hash2 = service.computeSignatureHash(
            workflowId: "wf-002", // Different workflow
            stepNumber: 1,
            signerId: "user-001",
            signerName: "John Doe",
            signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-12345678",
            attestationText: "I confirm this is accurate.",
            signatureImageData: imageData
        )

        XCTAssertNotEqual(hash1, hash2, "Different inputs should produce different hashes")
    }

    func testSignatureHashIsSHA256Length() {
        let imageData = Data("test".utf8)

        let hash = service.computeSignatureHash(
            workflowId: "wf-001",
            stepNumber: 1,
            signerId: "user-001",
            signerName: "Test",
            signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-001",
            attestationText: "Test",
            signatureImageData: imageData
        )

        // SHA-256 produces 64 hex characters
        XCTAssertEqual(hash.count, 64, "SHA-256 hash should be 64 hex characters")
    }

    func testSignatureHashIsHexEncoded() {
        let imageData = Data("test".utf8)

        let hash = service.computeSignatureHash(
            workflowId: "wf-001",
            stepNumber: 1,
            signerId: "user-001",
            signerName: "Test",
            signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-001",
            attestationText: "Test",
            signatureImageData: imageData
        )

        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertTrue(
            hash.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) },
            "Hash should only contain hex characters"
        )
    }

    func testSignatureHashChangesWithDifferentTimestamp() {
        let imageData = Data("test".utf8)

        let hash1 = service.computeSignatureHash(
            workflowId: "wf-001", stepNumber: 1, signerId: "user-001",
            signerName: "Test", signerRole: "worker",
            timestamp: "2026-03-10T10:00:00Z",
            deviceId: "DEV-001", attestationText: "Test",
            signatureImageData: imageData
        )

        let hash2 = service.computeSignatureHash(
            workflowId: "wf-001", stepNumber: 1, signerId: "user-001",
            signerName: "Test", signerRole: "worker",
            timestamp: "2026-03-10T10:00:01Z", // 1 second later
            deviceId: "DEV-001", attestationText: "Test",
            signatureImageData: imageData
        )

        XCTAssertNotEqual(hash1, hash2, "Different timestamps should produce different hashes")
    }

    // MARK: - Signature Record Creation

    func testCreateSignatureRecord() {
        let user = MockData.workerUser
        let imageData = Data("test-image".utf8)

        let record = service.createSignatureRecord(
            workflowId: MockData.activeWorkflow.id,
            stepNumber: 1,
            signer: user,
            signatureImageData: imageData,
            attestationText: "I confirm this is accurate."
        )

        XCTAssertEqual(record.workflowId, MockData.activeWorkflow.id)
        XCTAssertEqual(record.stepNumber, 1)
        XCTAssertEqual(record.signerId, user.id)
        XCTAssertEqual(record.signerName, user.displayName)
        XCTAssertEqual(record.signerRole, user.role.rawValue)
        XCTAssertEqual(record.signatureImageData, imageData)
        XCTAssertFalse(record.contentHash.isEmpty)
        XCTAssertFalse(record.synced)
    }
}
