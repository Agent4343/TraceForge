import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var syncService = SyncService.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            MyTasksScreen()
                .tabItem {
                    Label(AppTab.myTasks.rawValue, systemImage: AppTab.myTasks.icon)
                }
                .tag(AppTab.myTasks)

            WorkflowsListScreen()
                .tabItem {
                    Label(AppTab.workflows.rawValue, systemImage: AppTab.workflows.icon)
                }
                .tag(AppTab.workflows)

            if let user = appState.currentUser, user.role.canCreateTemplates {
                TemplateLibraryScreen()
                    .tabItem {
                        Label(AppTab.templates.rawValue, systemImage: AppTab.templates.icon)
                    }
                    .tag(AppTab.templates)
            }

            ProfileScreen()
                .tabItem {
                    Label(AppTab.profile.rawValue, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)
        }
        .tint(FFColors.accentCyan)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FFColors.primaryNavy)

        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0.5))
        borderView.backgroundColor = UIColor(FFColors.border)

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(FFColors.tabInactive)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(FFColors.tabInactive)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(FFColors.accentCyan)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(FFColors.accentCyan)]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
