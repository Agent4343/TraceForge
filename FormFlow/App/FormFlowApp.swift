import SwiftUI
import UserNotifications

@main
struct FormFlowApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var syncService = SyncService.shared
    @StateObject private var storeKitService = StoreKitService.shared
    @StateObject private var biometricService = BiometricService.shared
    @StateObject private var notificationService = NotificationService.shared

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(syncService)
                .environmentObject(storeKitService)
                .environmentObject(biometricService)
                .environmentObject(notificationService)
                .preferredColorScheme(.dark)
                .task {
                    await storeKitService.loadProducts()
                    await storeKitService.updatePurchasedProducts()
                    await notificationService.checkPermissionStatus()
                    notificationService.registerCategories()
                }
        }
    }
}

// MARK: - App Delegate (APNs)

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationService.shared.handleRegistrationError(error)
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var biometricService: BiometricService
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass

    @State private var showSplash = true
    @State private var needsBiometricUnlock = false

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else if needsBiometricUnlock {
                BiometricLockScreen {
                    needsBiometricUnlock = false
                }
                .transition(.opacity)
            } else if !appState.isAuthenticated {
                LoginScreen()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: showSplash)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: appState.isAuthenticated)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.3), value: needsBiometricUnlock)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSplash = false
                }
                if appState.requireBiometrics && biometricService.isAvailable {
                    needsBiometricUnlock = true
                }
            }
        }
    }
}

// MARK: - Biometric Lock Screen

struct BiometricLockScreen: View {
    @EnvironmentObject var biometricService: BiometricService
    let onUnlock: () -> Void

    @State private var showError = false

    var body: some View {
        ZStack {
            FFColors.primaryNavy.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: biometricService.biometricType.iconName)
                    .font(.system(size: 64, weight: .thin))
                    .foregroundColor(FFColors.accentCyan)

                Text("FormFlow is Locked")
                    .font(FFTypography.displaySmall())
                    .foregroundColor(FFColors.textPrimary)

                Text("Use \(biometricService.biometricType.displayName) to unlock")
                    .font(FFTypography.bodyMedium())
                    .foregroundColor(FFColors.textSecondary)

                if showError, let error = biometricService.errorMessage {
                    Text(error)
                        .font(FFTypography.bodySmall())
                        .foregroundColor(FFColors.danger)
                }

                Spacer()

                Button("Unlock") {
                    authenticate()
                }
                .ffPrimaryButton()
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            authenticate()
        }
    }

    private func authenticate() {
        Task {
            let success = await biometricService.authenticate(reason: "Unlock FormFlow to access your workflows")
            if success {
                onUnlock()
            } else {
                showError = true
            }
        }
    }
}
