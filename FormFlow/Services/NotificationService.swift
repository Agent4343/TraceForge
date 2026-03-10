import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Service

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isPermissionGranted: Bool = false
    @Published var deviceToken: String?

    override init() {
        super.init()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isPermissionGranted = granted
            if granted {
                await registerForRemoteNotifications()
            }
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        isPermissionGranted = settings.authorizationStatus == .authorized
    }

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Token Management

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token

        Task {
            try? await UserService.shared.updateDeviceToken(token)
        }
    }

    func handleRegistrationError(_ error: Error) {
        print("APNs registration failed: \(error)")
    }

    // MARK: - Local Notifications

    func scheduleDueDateReminder(taskName: String, dueDate: Date, advanceHours: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = "Reminder: \(taskName) is due in \(advanceHours) hours"
        content.sound = .default
        content.categoryIdentifier = "TASK_REMINDER"

        let triggerDate = dueDate.addingTimeInterval(-Double(advanceHours) * 3600)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "due-reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleOverdueAlert(taskName: String, workflowName: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Task Overdue"
        content.body = "\(taskName) is now overdue — \(workflowName)"
        content.sound = .defaultCritical
        content.categoryIdentifier = "TASK_OVERDUE"

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "overdue-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Handle Received Notification

    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        let workflowId = (userInfo["workflow_id"] as? String).flatMap(UUID.init(uuidString:))
        let appState = AppState.shared

        switch type {
        case "step_assigned", "handover_received":
            appState.selectedTab = .myTasks
            appState.deepLink = .myTasks

        case "step_due_soon", "step_overdue":
            appState.selectedTab = .myTasks
            if let workflowId {
                appState.deepLink = .task(workflowId: workflowId)
            }

        case "step_completed", "workflow_complete":
            appState.selectedTab = .workflows
            if let workflowId {
                appState.deepLink = .workflowDetail(workflowId: workflowId)
            }

        case "sync_conflict":
            appState.deepLink = .syncConflict

        default:
            break
        }
    }

    // MARK: - Notification Categories

    func registerCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_TASK",
            title: "View Task",
            options: .foreground
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [viewAction],
            intentIdentifiers: []
        )

        let overdueCategory = UNNotificationCategory(
            identifier: "TASK_OVERDUE",
            actions: [viewAction],
            intentIdentifiers: []
        )

        let handoverAction = UNNotificationAction(
            identifier: "ACCEPT_HANDOVER",
            title: "Accept",
            options: .foreground
        )

        let handoverCategory = UNNotificationCategory(
            identifier: "HANDOVER",
            actions: [handoverAction, viewAction],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            taskCategory, overdueCategory, handoverCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        await handleNotification(userInfo: userInfo)
    }
}
