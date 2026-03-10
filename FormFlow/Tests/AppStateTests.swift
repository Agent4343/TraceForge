import XCTest
@testable import FormFlow

@MainActor
final class AppStateTests: XCTestCase {
    var appState: AppState!

    override func setUp() async throws {
        appState = AppState()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.currentUser)
        XCTAssertNil(appState.organization)
        XCTAssertTrue(appState.isOnline)
        XCTAssertEqual(appState.selectedTab, .myTasks)
    }

    // MARK: - Login

    func testLoginSetsAuthenticated() {
        let expectation = XCTestExpectation(description: "Login completes")

        appState.login(email: "admin@test.com", password: "password")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(self.appState.isAuthenticated)
            XCTAssertNotNil(self.appState.currentUser)
            XCTAssertNotNil(self.appState.organization)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testAdminEmailGetsAdminRole() {
        let expectation = XCTestExpectation(description: "Login completes")

        appState.login(email: "admin@test.com", password: "password")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(self.appState.currentUser?.role, .admin)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testManagerEmailGetsManagerRole() {
        let expectation = XCTestExpectation(description: "Login completes")

        appState.login(email: "manager@test.com", password: "password")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertEqual(self.appState.currentUser?.role, .manager)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    // MARK: - Logout

    func testLogoutClearsState() {
        appState.isAuthenticated = true
        appState.currentUser = MockData.workerUser
        appState.organization = MockData.organization
        appState.selectedTab = .workflows

        appState.logout()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertNil(appState.currentUser)
        XCTAssertNil(appState.organization)
        XCTAssertEqual(appState.selectedTab, .myTasks)
    }

    // MARK: - Data Access

    func testStepsForWorkflow() {
        let steps = appState.stepsForWorkflow(MockData.activeWorkflow.id)
        XCTAssertFalse(steps.isEmpty)
        XCTAssertTrue(steps.allSatisfy { $0.workflowId == MockData.activeWorkflow.id })
    }

    func testTemplateForWorkflow() {
        let template = appState.templateForWorkflow(MockData.activeWorkflow)
        XCTAssertNotNil(template)
        XCTAssertEqual(template?.id, MockData.preJobSafetyTemplate.id)
    }

    func testAuditEntriesForWorkflow() {
        let entries = appState.auditEntriesForWorkflow(MockData.activeWorkflow.id)
        XCTAssertFalse(entries.isEmpty)
        XCTAssertTrue(entries.allSatisfy { $0.workflowId == MockData.activeWorkflow.id })
        // Should be sorted descending by timestamp
        for i in 0..<(entries.count - 1) {
            XCTAssertGreaterThanOrEqual(entries[i].timestamp, entries[i + 1].timestamp)
        }
    }

    // MARK: - Form Responses

    func testSaveAndGetResponse() {
        let workflowId = UUID()
        let fieldId = UUID()

        appState.saveResponse(workflowId: workflowId, fieldId: fieldId, value: "42.5")

        let retrieved = appState.getResponse(workflowId: workflowId, fieldId: fieldId)
        XCTAssertEqual(retrieved, "42.5")
    }

    func testGetResponseReturnsNilForMissing() {
        let result = appState.getResponse(workflowId: UUID(), fieldId: UUID())
        XCTAssertNil(result)
    }

    func testOverwriteResponse() {
        let workflowId = UUID()
        let fieldId = UUID()

        appState.saveResponse(workflowId: workflowId, fieldId: fieldId, value: "old")
        appState.saveResponse(workflowId: workflowId, fieldId: fieldId, value: "new")

        XCTAssertEqual(appState.getResponse(workflowId: workflowId, fieldId: fieldId), "new")
    }

    // MARK: - Mock Data Loaded

    func testInitialMockDataLoaded() {
        XCTAssertFalse(appState.templates.isEmpty)
        XCTAssertFalse(appState.workflows.isEmpty)
        XCTAssertFalse(appState.stepAssignments.isEmpty)
        XCTAssertFalse(appState.auditLog.isEmpty)
        XCTAssertFalse(appState.users.isEmpty)
    }
}
